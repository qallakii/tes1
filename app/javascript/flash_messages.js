function initFlashMessages() {
  document.querySelectorAll("[data-auto-dismiss]").forEach((flash) => {
    if (flash.dataset.dismissBound === "1") return;
    flash.dataset.dismissBound = "1";

    const delay = Number.parseInt(flash.dataset.autoDismiss || "3000", 10);

    window.setTimeout(() => {
      flash.classList.add("is-dismissing");

      window.setTimeout(() => {
        flash.remove();
      }, 250);
    }, delay);
  });
}

document.addEventListener("turbo:load", initFlashMessages);
document.addEventListener("DOMContentLoaded", initFlashMessages);
