function initRecentsIndexPage() {
  const page = document.querySelector("[data-recents-index]");
  if (!page) return;

  const searchInput = page.querySelector("#recent-search");
  const rows = Array.from(page.querySelectorAll(".recent-row"));
  const noResults = page.querySelector("#recent-no-results");

  function humanSize(bytes) {
    const units = ["B", "KB", "MB", "GB", "TB"];
    let value = Number(bytes || 0);
    let unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }

    return `${unitIndex === 0 ? value.toFixed(0) : value.toFixed(1)} ${units[unitIndex]}`;
  }

  page.querySelectorAll("[data-size-text]").forEach((element) => {
    const rawValue = parseInt(element.textContent || "0", 10);
    element.textContent = humanSize(rawValue);
  });

  function applyFilters() {
    const query = (searchInput?.value || "").trim().toLowerCase();
    let visibleCount = 0;

    rows.forEach((row) => {
      const name = row.dataset.name || "";
      const type = row.dataset.type || "";
      const match = !query || name.includes(query) || type.includes(query);
      row.hidden = !match;
      if (match) visibleCount += 1;
    });

    if (noResults) noResults.hidden = !(query && visibleCount === 0);
  }

  if (searchInput) searchInput.addEventListener("input", applyFilters);
  applyFilters();
}

document.addEventListener("turbo:load", initRecentsIndexPage);
