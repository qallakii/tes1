# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "copy_buttons", to: "copy_buttons.js"
pin "folder_show", to: "folder_show.js"
pin "profile_dropdown", to: "profile_dropdown.js"
pin "share_modal", to: "share_modal.js"
