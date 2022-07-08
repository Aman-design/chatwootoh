# == Schema Information
#
# Table name: portals
#
#  id            :bigint           not null, primary key
#  archived      :boolean          default(FALSE)
#  color         :string
#  config        :jsonb
#  custom_domain :string
#  header_text   :text
#  homepage_link :string
#  name          :string           not null
#  page_title    :string
#  slug          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#
# Indexes
#
#  index_portals_on_slug  (slug) UNIQUE
#
class Portal < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :account
  has_many :categories, dependent: :destroy_async
  has_many :folders,  through: :categories
  has_many :articles, dependent: :destroy_async
  has_many :portal_members,
           class_name: :PortalMember,
           dependent: :destroy_async
  has_many :members,
           through: :portal_members,
           class_name: :User,
           dependent: :nullify,
           source: :user
  has_one_attached :logo

  validates :account_id, presence: true
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :config_json_format

  accepts_nested_attributes_for :members

  scope :active, -> { where(archived: false) }

  CONFIG_JSON_KEYS = %w[allowed_locales].freeze

  def file_base_data
    {
      id: logo.id,
      portal_id: id,
      file_type: logo.content_type,
      account_id: account_id,
      file_url: url_for(logo),
      blob_id: logo.blob_id,
      filename: logo.filename.to_s
    }
  end

  private

  def config_json_format
    denied_keys = config.keys - CONFIG_JSON_KEYS
    errors.add(:cofig, "in portal on #{denied_keys.join(',')} is not supported.") if denied_keys.any?
  end
end
