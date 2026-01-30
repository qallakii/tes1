function initProfileDropdown() {
  const btn = document.getElementById("profileBtn");
  const menu = document.getElementById("profileMenu");

  if (!btn || !menu) return;

  if (btn.dataset.dropdownBound === "1") return;
  btn.dataset.dropdownBound = "1";

  const closeMenu = () => menu.classList.remove("open");

  btn.addEventListener("click", (e) => {
    e.preventDefault();
    e.stopPropagation();
    menu.classList.toggle("open");
  });

  document.addEventListener("click", (e) => {
    if (!btn.contains(e.target) && !menu.contains(e.target)) {
      closeMenu();
    }
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeMenu();
  });
}

document.addEventListener("turbo:load", initProfileDropdown);
document.addEventListener("DOMContentLoaded", initProfileDropdown);
