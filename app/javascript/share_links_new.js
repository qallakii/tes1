function initShareLinksNewPage() {
  const page = document.querySelector("[data-share-links-new]");
  if (!page) return;

  const selectAll = page.querySelector("#select-all");
  const checks = Array.from(page.querySelectorAll(".cv-check"));
  const submitButton = page.querySelector("#share-selected-btn");

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

  function updateSelectionState() {
    const anyChecked = checks.some((checkbox) => checkbox.checked);
    if (submitButton) submitButton.disabled = !anyChecked;
    if (selectAll) selectAll.checked = checks.length > 0 && checks.every((checkbox) => checkbox.checked);
  }

  if (selectAll) {
    selectAll.addEventListener("change", () => {
      checks.forEach((checkbox) => {
        checkbox.checked = selectAll.checked;
      });
      updateSelectionState();
    });
  }

  checks.forEach((checkbox) => {
    checkbox.addEventListener("change", updateSelectionState);
  });

  updateSelectionState();
}

document.addEventListener("turbo:load", initShareLinksNewPage);
