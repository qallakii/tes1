document.addEventListener("DOMContentLoaded", () => {
  // Works on folder show page if file rows exist
  const rows = document.querySelectorAll("[data-file-row]");
  if (!rows.length) return;

  const uploadBtn =
    document.getElementById("open-upload") ||
    document.querySelector("[data-upload-btn]");

  const toolbar =
    document.getElementById("bulk-toolbar") ||
    document.querySelector("[data-bulk-toolbar]");

  const CLICK_DELAY = 220; // delay to distinguish click vs dblclick
  let clickTimer = null;

  function checkedCount() {
    return document.querySelectorAll("[data-file-checkbox]:checked").length;
  }

  function updateToolbar() {
    const any = checkedCount() > 0;

    // Show/hide toolbar (bulk actions)
    if (toolbar) toolbar.style.display = any ? "" : "none";

    // Hide upload when something is selected
    if (uploadBtn) uploadBtn.style.display = any ? "none" : "";
  }

  // Keep toolbar correct on load
  updateToolbar();

  // If user clicks checkbox directly, still update toolbar
  document.addEventListener("change", (e) => {
    if (e.target && e.target.matches("[data-file-checkbox]")) updateToolbar();
  });

  rows.forEach((row) => {
    const checkbox = row.querySelector("[data-file-checkbox]");
    if (!checkbox) return;

    const previewUrl = row.dataset.previewUrl;

    // Single click toggles selection (but delayed so dblclick cancels it)
    row.addEventListener("click", (e) => {
      // If user clicks a real control inside row, do nothing
      if (e.target.closest("a, button, input, label")) return;

      clearTimeout(clickTimer);
      clickTimer = setTimeout(() => {
        checkbox.checked = !checkbox.checked;
        checkbox.dispatchEvent(new Event("change", { bubbles: true }));
        updateToolbar();
      }, CLICK_DELAY);
    });

    // Double click opens preview
    row.addEventListener("dblclick", (e) => {
      if (e.target.closest("a, button, input, label")) return;

      clearTimeout(clickTimer);
      if (previewUrl) window.open(previewUrl, "_blank", "noopener");
    });
  });
});
