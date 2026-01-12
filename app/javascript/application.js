import "@hotwired/turbo-rails"
import "controllers"
import "./folder_show"


// Enable Rails UJS for method: :delete links
import Rails from "@rails/ujs"
Rails.start()

document.addEventListener("DOMContentLoaded", () => {
  const toggle = document.getElementById("profileToggle")
  const dropdown = document.querySelector(".user-dropdown .dropdown-menu")

  if (toggle && dropdown) {
    // Toggle dropdown on click
    toggle.addEventListener("click", (e) => {
      e.stopPropagation()
      dropdown.classList.toggle("open")
    })

    // Close dropdown when clicking outside
    document.addEventListener("click", (e) => {
      if (!toggle.contains(e.target) && !dropdown.contains(e.target)) {
        dropdown.classList.remove("open")
      }
    })
  }
})
