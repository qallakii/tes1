# frozen_string_literal: true

module ShareLinks
  class Create
    Result = Struct.new(:share_link, :url, keyword_init: true)

    def initialize(user:, folder_id:, cv_ids:, return_to:, url_helpers:)
      @user = user
      @folder_id = folder_id
      @cv_ids = Array(cv_ids).map(&:to_s).reject(&:blank?)
      @return_to = return_to
      @url_helpers = url_helpers
    end

    def call
      folder = @user.folders.find(@folder_id)
      share_link = folder.share_links.create!

      if @cv_ids.any?
        allowed_ids = folder.cvs.where(id: @cv_ids).pluck(:id)
        allowed_ids.each do |id|
          ShareLinkCv.create!(share_link: share_link, cv_id: id)
        end
      end

      url = @url_helpers.share_link_url(share_link.token)
      Result.new(share_link: share_link, url: url)
    end
  end
end
