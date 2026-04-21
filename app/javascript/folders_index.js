function initFoldersIndexPage() {
  const page = document.querySelector("[data-folders-index]");
  if (!page) return;

  if (window.__foldersIndexAbort) window.__foldersIndexAbort.abort();
  window.__foldersIndexAbort = new AbortController();
  const { signal } = window.__foldersIndexAbort;

  const searchInput = page.querySelector("#folder-search");
  const sortSelect = page.querySelector("#folder-sort");
  const selectAll = page.querySelector("#select-all-folders");
  const shareButton = page.querySelector("#bulk-share-btn");
  const downloadButton = page.querySelector("#bulk-download-btn");
  const noResults = page.querySelector("#folder-no-results");
  const list = page.querySelector(".folders-list");

  const createOverlay = page.querySelector("#create-folder-overlay");
  const openCreateButton = page.querySelector("#open-create-folder");
  const closeCreateButton = page.querySelector("#close-create-folder");
  const cancelCreateButton = page.querySelector("#cancel-create-folder");
  const createInput = page.querySelector(".folder-create-modal-input");

  function openCreateModal() {
    if (!createOverlay) return;
    createOverlay.style.display = "flex";
    if (createInput) {
      createInput.focus();
      createInput.select();
    }
  }

  function closeCreateModal() {
    if (createOverlay) createOverlay.style.display = "none";
  }

  if (openCreateButton) openCreateButton.addEventListener("click", openCreateModal, { signal });
  if (closeCreateButton) closeCreateButton.addEventListener("click", closeCreateModal, { signal });
  if (cancelCreateButton) cancelCreateButton.addEventListener("click", closeCreateModal, { signal });
  if (createOverlay) {
    createOverlay.addEventListener("click", (event) => {
      if (event.target === createOverlay) closeCreateModal();
    }, { signal });
  }
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && createOverlay && createOverlay.style.display === "flex") {
      closeCreateModal();
    }
  }, { signal });

  if (!list) return;

  const rows = Array.from(list.querySelectorAll(".folder-row"));
  const checkboxes = () => rows.map((row) => row.querySelector(".folder-select")).filter(Boolean);

  function selectedFolderIds() {
    return checkboxes().filter((checkbox) => checkbox.checked).map((checkbox) => checkbox.value);
  }

  function updateBulkActions() {
    const hasSelection = selectedFolderIds().length > 0;

    [shareButton, downloadButton].forEach((button) => {
      if (!button) return;
      button.hidden = !hasSelection;
    });

    if (selectAll) {
      const all = checkboxes();
      selectAll.checked = all.length > 0 && all.every((checkbox) => checkbox.checked);
    }
  }

  function applyFilters() {
    const query = (searchInput?.value || "").trim().toLowerCase();
    const sortValue = sortSelect?.value || "updated_desc";

    rows.forEach((row) => {
      const name = row.dataset.name || "";
      const visible = !query || name.includes(query);
      row.hidden = !visible;
    });

    const visibleRows = rows.filter((row) => !row.hidden);
    visibleRows.sort((left, right) => {
      const leftName = left.dataset.name || "";
      const rightName = right.dataset.name || "";
      const leftUpdated = Number(left.dataset.updated || 0);
      const rightUpdated = Number(right.dataset.updated || 0);

      switch (sortValue) {
        case "name_asc":
          return leftName.localeCompare(rightName);
        case "name_desc":
          return rightName.localeCompare(leftName);
        case "updated_asc":
          return leftUpdated - rightUpdated;
        default:
          return rightUpdated - leftUpdated;
      }
    });

    visibleRows.forEach((row) => list.appendChild(row));

    if (noResults) noResults.hidden = !(query && visibleRows.length === 0);
  }

  rows.forEach((row) => {
    row.addEventListener("click", (event) => {
      if (event.target.closest("a, button, input, form")) return;
      const link = row.querySelector(".folder-link");
      if (link) window.location.href = link.href;
    }, { signal });
  });

  checkboxes().forEach((checkbox) => {
    checkbox.addEventListener("change", updateBulkActions, { signal });
  });

  if (selectAll) {
    selectAll.addEventListener("change", () => {
      checkboxes().forEach((checkbox) => {
        checkbox.checked = selectAll.checked;
      });
      updateBulkActions();
    }, { signal });
  }

  if (shareButton) {
    shareButton.addEventListener("click", () => {
      const folderIds = selectedFolderIds();
      if (folderIds.length === 0 || typeof window.openShareModal !== "function") return;
      window.openShareModal({ folderIds, cvIds: [] });
    }, { signal });
  }

  if (searchInput) searchInput.addEventListener("input", applyFilters, { signal });
  if (sortSelect) sortSelect.addEventListener("change", applyFilters, { signal });

  document.addEventListener("turbo:before-cache", () => {
    if (window.__foldersIndexAbort) window.__foldersIndexAbort.abort();
  }, { signal, once: true });

  updateBulkActions();
  applyFilters();
}

document.addEventListener("turbo:load", initFoldersIndexPage);
