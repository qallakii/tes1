import "@hotwired/turbo-rails"
import { initActionsMenus } from "actions_menu"
import "copy_buttons"
import "controllers"
import "flash_messages"
import "folder_show"
import "folders_index"
import "mobile_nav"
import "profile_dropdown"
import "recents_index"
import "share_modal"
import "share_links_new"
import "shared_with_me"

initActionsMenus()

// IMPORTANT:
// Do NOT import "@rails/ujs" when using importmap unless you explicitly pinned it.
// Turbo handles method links (data-turbo-method) and confirmations (data-turbo-confirm).
