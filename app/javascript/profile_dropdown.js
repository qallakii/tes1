document.addEventListener("DOMContentLoaded", function() {
  const toggle = document.getElementById("profileToggle");
  const menu = document.getElementById("profileMenu");

  if (toggle) {
    toggle.addEventListener("click", function(e) {
      e.stopPropagation();
      menu.style.display = menu.style.display === "block" ? "none" : "block";
    });

    document.addEventListener("click", function() {
      if (menu) menu.style.display = "none";
    });
  }
});
