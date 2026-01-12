import "@hotwired/turbo-rails"
import "controllers"
import "./folder_show"

// Auto-hide flash messages after 3 seconds
document.addEventListener("turbo:load", () => {
  const flashes = document.querySelectorAll(".flash");
  if (!flashes.length) return;

  flashes.forEach((flash) => {
    setTimeout(() => {
      flash.style.transition = "opacity 0.4s ease, transform 0.4s ease";
      flash.style.opacity = "0";
      flash.style.transform = "translateY(-6px)";

      setTimeout(() => {
        flash.remove();
      }, 400);
    }, 3000);
  });
});


// Enable Rails UJS for method: :delete links
import Rails from "@rails/ujs"
Rails.start()

document.addEventListener("turbo:load", () => {
  const toggle = document.getElementById("profileToggle")
  const dropdown = document.querySelector(".user-dropdown .dropdown-menu")

  if (toggle && dropdown) {
    toggle.addEventListener("click", (e) => {
      e.stopPropagation()
      dropdown.classList.toggle("open")
    })

    document.addEventListener("click", (e) => {
      if (!toggle.contains(e.target) && !dropdown.contains(e.target)) {
        dropdown.classList.remove("open")
      }
    })
  }
})