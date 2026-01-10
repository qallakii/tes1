# frozen_string_literal: true

module OwnershipScopes
  extend ActiveSupport::Concern

  private

  def owned_folder(id)
    current_user.folders.find(id)
  end

  def owned_share_link(id)
    ShareLink
      .joins(:folder)
      .where(folders: { user_id: current_user.id })
      .find(id)
  end

  def owned_share_links_scope
    ShareLink
      .joins(:folder)
      .where(folders: { user_id: current_user.id })
  end
end
