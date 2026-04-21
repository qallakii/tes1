class SharedWithMeController < ApplicationController
  before_action :require_login

  SharedEntry = Struct.new(:share_link, :sender, :item_type, :folder, :cv, :permission, keyword_init: true)

  def index
    received_links = current_user.accessible_share_links
      .includes(:user, :folders, :cvs, :folder)
      .where.not(user_id: current_user.id)
      .order(created_at: :desc)
      .to_a
      .reject { |link| link.expired? || link.disabled? }

    @shared_entries = []
    seen_folders = {}
    seen_files = {}

    received_links.each do |share_link|
      sender = share_link.user
      permission = share_link.permission_for(current_user)

      share_link.all_folders.each do |folder|
        next if seen_folders[folder.id]

        seen_folders[folder.id] = true
        @shared_entries << SharedEntry.new(
          share_link: share_link,
          sender: sender,
          item_type: :folder,
          folder: folder,
          permission: permission
        )
      end

      share_link.cvs.each do |cv|
        next if seen_files[cv.id]

        seen_files[cv.id] = true
        @shared_entries << SharedEntry.new(
          share_link: share_link,
          sender: sender,
          item_type: :file,
          cv: cv,
          permission: permission
        )
      end
    end
  end
end
