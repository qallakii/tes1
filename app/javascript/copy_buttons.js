function initCopyButtons() {
  if (window.__copyButtonsBound) return;
  window.__copyButtonsBound = true;

  document.addEventListener("click", async (e) => {
    const button = e.target.closest("[data-copy]");
    if (!button) return;

    const text = button.getAttribute("data-copy");
    if (!text) return;

    try {
      await navigator.clipboard.writeText(text);
      const originalText = button.textContent;
      button.textContent = "Copied";
      window.setTimeout(() => {
        button.textContent = originalText;
      }, 1200);
    } catch (_error) {
      window.alert("Copy failed. Please copy the link manually.");
    }
  });
}

document.addEventListener("turbo:load", initCopyButtons);
document.addEventListener("DOMContentLoaded", initCopyButtons);
