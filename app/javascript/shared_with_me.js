function initSharedWithMePage() {
  const page = document.querySelector("[data-shared-with-me]");
  if (!page) return;

  if (window.__sharedWithMeAbort) window.__sharedWithMeAbort.abort();
  window.__sharedWithMeAbort = new AbortController();
  const { signal } = window.__sharedWithMeAbort;

  page.querySelectorAll(".shared-item-row").forEach((row) => {
    row.addEventListener("click", (event) => {
      if (event.target.closest("a, button, form")) return;
      const openUrl = row.dataset.openUrl;
      if (openUrl) window.location.href = openUrl;
    }, { signal });
  });
}

document.addEventListener("turbo:load", initSharedWithMePage);
