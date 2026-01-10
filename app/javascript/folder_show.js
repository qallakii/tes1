// app/javascript/folder_show.js
function initFolderShowPage() {
  // run only on folder show page
  const listEl = document.querySelector(".cvs-list");
  if (!listEl) return;

  // prevent double-binding across turbo navigations
  if (document.body.dataset.folderShowBound === "true") return;
  document.body.dataset.folderShowBound = "true";

  // format sizes
  function humanSize(bytes) {
    const units = ["B","KB","MB","GB","TB"];
    let b = Number(bytes || 0);
    let i = 0;
    while (b >= 1024 && i < units.length - 1) { b = b / 1024; i++; }
    return (i === 0 ? b.toFixed(0) : b.toFixed(1)) + " " + units[i];
  }

  document.querySelectorAll("[data-size-text]").forEach((el) => {
    const raw = parseInt(el.textContent || "0", 10);
    el.textContent = humanSize(raw);
  });

  // upload modal
  const uploadOverlay = document.getElementById("upload-overlay");
  const openUpload = document.getElementById("open-upload");
  const closeUpload = document.getElementById("close-upload");

  if (openUpload && uploadOverlay) openUpload.addEventListener("click", () => uploadOverlay.style.display = "flex");
  if (closeUpload && uploadOverlay) closeUpload.addEventListener("click", () => uploadOverlay.style.display = "none");
  if (uploadOverlay) uploadOverlay.addEventListener("click", (e) => { if (e.target === uploadOverlay) uploadOverlay.style.display = "none"; });

  // row click preview
  document.querySelectorAll(".clickable-row").forEach((row) => {
    row.addEventListener("click", (e) => {
      if (e.target.closest(".col-cv-check")) return;
      if (e.target.closest(".kebab-wrap")) return;
      const url = row.getAttribute("data-preview");
      if (url) window.open(url, "_blank");
    });
  });

  // select + bulk actions
  const selectAll = document.getElementById("select-all");
  const checks = Array.from(document.querySelectorAll(".cv-check"));
  const bulkBar = document.getElementById("bulk-actions");
  const bulkCount = document.getElementById("bulk-count");

  function selectedIds() {
    return checks.filter(c => c.checked).map(c => c.value);
  }
  function selectedRows() {
    return checks.filter(c => c.checked).map(c => c.closest(".cv-row"));
  }

  function updateBulk() {
    const count = selectedIds().length;
    const any = count > 0;

    if (bulkBar) bulkBar.style.display = any ? "flex" : "none";
    if (bulkCount) bulkCount.textContent = String(count);

    // ✅ hide upload when selection exists
    if (openUpload) openUpload.style.display = any ? "none" : "";

    if (selectAll) selectAll.checked = checks.length > 0 && checks.every(c => c.checked);
  }

  if (selectAll) {
    selectAll.addEventListener("change", () => {
      checks.forEach(c => c.checked = selectAll.checked);
      updateBulk();
    });
  }
  checks.forEach(c => c.addEventListener("change", updateBulk));
  updateBulk();

  // bulk clear (X)
  const bulkClear = document.getElementById("bulk-clear");
  if (bulkClear) {
    bulkClear.addEventListener("click", () => {
      checks.forEach(c => c.checked = false);
      if (selectAll) selectAll.checked = false;
      updateBulk();
    });
  }

  // bulk share
  const bulkShare = document.getElementById("bulk-share");
  const shareForm = document.getElementById("share-selected-form");
  const shareIds = document.getElementById("selected-cv-ids");

  if (bulkShare && shareForm && shareIds) {
    bulkShare.addEventListener("click", () => {
      const ids = selectedIds();
      shareIds.innerHTML = "";
      ids.forEach((id) => {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = "cv_ids[]";
        input.value = id;
        shareIds.appendChild(input);
      });
      shareForm.submit();
    });
  }

  // bulk download
  const bulkDownload = document.getElementById("bulk-download");
  if (bulkDownload) {
    bulkDownload.addEventListener("click", () => {
      selectedRows().forEach((row, idx) => {
        const url = row.getAttribute("data-download");
        if (!url) return;
        setTimeout(() => {
          const a = document.createElement("a");
          a.href = url;
          a.download = "";
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
        }, idx * 150);
      });
    });
  }

  // bulk delete
  const bulkDelete = document.getElementById("bulk-delete");
  const bulkDeleteForm = document.getElementById("bulk-delete-form");
  const bulkDeleteIds = document.getElementById("bulk-delete-ids");

  if (bulkDelete && bulkDeleteForm && bulkDeleteIds) {
    bulkDelete.addEventListener("click", () => {
      if (!confirm("Delete selected files?")) return;
      const ids = selectedIds();
      bulkDeleteIds.innerHTML = "";
      ids.forEach((id) => {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = "cv_ids[]";
        input.value = id;
        bulkDeleteIds.appendChild(input);
      });
      bulkDeleteForm.submit();
    });
  }

  // kebab (portal to body to avoid clipping)
  let openMenu = null;
  let openBtn = null;

  function closeAllMenus() {
    document.querySelectorAll(".kebab-menu").forEach((m) => m.style.display = "none");
    openMenu = null;
    openBtn = null;
  }

  function positionMenu(btn, menu) {
    const r = btn.getBoundingClientRect();

    menu.style.position = "fixed";
    menu.style.zIndex = "99999";
    menu.style.display = "block";

    const mr = menu.getBoundingClientRect();

    let top = r.bottom + 8;
    let left = r.right - mr.width;

    if (top + mr.height > window.innerHeight - 8) top = r.top - mr.height - 8;
    if (left < 8) left = 8;
    if (left + mr.width > window.innerWidth - 8) left = window.innerWidth - mr.width - 8;
    if (top < 8) top = 8;

    menu.style.top = `${top}px`;
    menu.style.left = `${left}px`;
  }

  document.querySelectorAll("[data-kebab]").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();

      const key = btn.getAttribute("data-kebab");
      const menu = document.querySelector('[data-kebab-menu="' + key + '"]');
      if (!menu) return;

      const isOpen = (openMenu === menu && menu.style.display === "block");
      closeAllMenus();
      if (isOpen) return;

      if (menu.parentElement !== document.body) document.body.appendChild(menu);

      openMenu = menu;
      openBtn = btn;
      positionMenu(btn, menu);
    });
  });

  document.addEventListener("click", () => closeAllMenus());
  window.addEventListener("resize", () => { if (openMenu && openBtn) positionMenu(openBtn, openMenu); });
  window.addEventListener("scroll", () => { if (openMenu && openBtn) positionMenu(openBtn, openMenu); }, true);

  // share one
  const shareOneForm = document.getElementById("share-one-form");
  const shareOneContainer = document.getElementById("share-one-cv");

  document.querySelectorAll(".share-one-btn").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();

      const id = btn.getAttribute("data-cv-id");
      if (!id || !shareOneForm || !shareOneContainer) return;

      shareOneContainer.innerHTML = "";
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = "cv_ids[]";
      input.value = id;
      shareOneContainer.appendChild(input);

      shareOneForm.submit();
    });
  });
}

// Turbo hooks
document.addEventListener("turbo:load", initFolderShowPage);
document.addEventListener("turbo:render", initFolderShowPage);

// allow re-init after caching
document.addEventListener("turbo:before-cache", () => {
  delete document.body.dataset.folderShowBound;
});
