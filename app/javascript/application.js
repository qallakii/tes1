import "@hotwired/turbo-rails"

document.addEventListener("DOMContentLoaded", () => {
  const btn = document.getElementById("profileBtn")
  const menu = document.getElementById("profileMenu")

  if (btn && menu) {
    btn.addEventListener("click", () => {
      menu.classList.toggle("hidden")
    })

    document.addEventListener("click", (e) => {
      if (!btn.contains(e.target) && !menu.contains(e.target)) {
        menu.classList.add("hidden")
      }
    })
  }
})
