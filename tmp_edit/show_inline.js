
  function initFolderShow() {
    if (window.__folderShowInitDone) return;
    window.__folderShowInitDone = true;

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

    // selection
    const selectAll = document.getElementById("select-all");
    const checks = Array.from(document.querySelectorAll(".cv-check"));
    const bulkBar = document.getElementById("bulk-actions");

    function selectedIds() {
      return checks.filter(c => c.checked).map(c => c.value);
    }
    function selectedRows() {
      return checks.filter(c => c.checked).map(c => c.closest(".cv-row"));
    }
    function updateBulk() {
      const any = selectedIds().length > 0;
      if (bulkBar) bulkBar.style.display = any ? "flex" : "none";
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

    // single click select, double click preview
    const CLICK_DELAY = 220;
    let clickTimer = null;

    document.querySelectorAll(".clickable-row").forEach((row) => {
      const checkbox = row.querySelector(".cv-check");
      if (!checkbox) return;

      row.addEventListener("click", (e) => {
        if (e.target.closest(".col-cv-check")) return;
        if (e.target.closest(".kebab-wrap")) return;

        clearTimeout(clickTimer);
        clickTimer = setTimeout(() => {
          checkbox.checked = !checkbox.checked;
          checkbox.dispatchEvent(new Event("change", { bubbles: true }));
          updateBulk();
        }, CLICK_DELAY);
      });

      row.addEventListener("dblclick", (e) => {
        if (e.target.closest(".col-cv-check")) return;
        if (e.target.closest(".kebab-wrap")) return;

        clearTimeout(clickTimer);
        const url = row.getAttribute("data-preview");
        if (url) window.open(url, "_blank", "noopener");
      });
    });

    // ===== Expiry modal =====
    const expiryOverlay = document.getElementById("expiry-overlay");
    const closeExpiry = document.getElementById("close-expiry");
    const cancelExpiry = document.getElementById("expiry-cancel");
    const neverExpiry = document.getElementById("expiry-never");
    const confirmExpiry = document.getElementById("expiry-confirm");
    const expiryInput = document.getElementById("expiry-datetime");

    let pendingShareMode = null; // "bulk" or "one"
    let pendingOneId = null;

    function openExpiryModal(mode, oneId = null) {
      pendingShareMode = mode;
      pendingOneId = oneId;
      if (expiryInput) expiryInput.value = ""; // empty means Never
      if (expiryOverlay) expiryOverlay.style.display = "flex";
    }
    function closeExpiryModal() {
      if (expiryOverlay) expiryOverlay.style.display = "none";
      pendingShareMode = null;
      pendingOneId = null;
    }

    if (closeExpiry) closeExpiry.addEventListener("click", closeExpiryModal);
    if (cancelExpiry) cancelExpiry.addEventListener("click", closeExpiryModal);
    if (expiryOverlay) expiryOverlay.addEventListener("click", (e) => { if (e.target === expiryOverlay) closeExpiryModal(); });
    if (neverExpiry) neverExpiry.addEventListener("click", () => { if (expiryInput) expiryInput.value = ""; });

    // share forms + hidden expiry fields
    const shareForm = document.getElementById("share-selected-form");
    const shareIds = document.getElementById("selected-cv-ids");
    const shareExpiresBulk = document.getElementById("share-expires-at");

    const shareOneForm = document.getElementById("share-one-form");
    const shareOneContainer = document.getElementById("share-one-cv");
    const shareExpiresOne = document.getElementById("share-expires-at-one");

    // bulk share opens modal
    const bulkShare = document.getElementById("bulk-share");
    if (bulkShare && shareForm && shareIds) {
      bulkShare.addEventListener("click", () => {
        if (selectedIds().length === 0) return;
        openExpiryModal("bulk");
      });
    }

    // share one opens modal
    document.querySelectorAll(".share-one-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        const id = btn.getAttribute("data-cv-id");
        if (!id) return;
        openExpiryModal("one", id);
      });
    });

    // confirm creates link (bulk or one)
    if (confirmExpiry) {
      confirmExpiry.addEventListener("click", () => {
        const expiresAt = expiryInput ? expiryInput.value : "";

        if (pendingShareMode === "bulk") {
          if (shareExpiresBulk) shareExpiresBulk.value = expiresAt;

          shareIds.innerHTML = "";
          selectedIds().forEach((id) => {
            const input = document.createElement("input");
            input.type = "hidden";
            input.name = "cv_ids[]";
            input.value = id;
            shareIds.appendChild(input);
          });

          closeExpiryModal();
          shareForm.submit();
        }

        if (pendingShareMode === "one") {
          if (shareExpiresOne) shareExpiresOne.value = expiresAt;

          shareOneContainer.innerHTML = "";
          const input = document.createElement("input");
          input.type = "hidden";
          input.name = "cv_ids[]";
          input.value = pendingOneId;
          shareOneContainer.appendChild(input);

          closeExpiryModal();
          shareOneForm.submit();
        }
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

    // kebab menu
    function closeAllMenus() {
      document.querySelectorAll(".kebab-menu").forEach((m) => m.style.display = "none");
    }
    document.querySelectorAll("[data-kebab]").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        const key = btn.getAttribute("data-kebab");
        const menu = document.querySelector('[data-kebab-menu="' + key + '"]');
        if (!menu) return;
        const isOpen = menu.style.display === "block";
        closeAllMenus();
        menu.style.display = isOpen ? "none" : "block";
      });
    });
    document.addEventListener("click", () => closeAllMenus());
  }

  document.addEventListener("turbo:load", () => {
    window.__folderShowInitDone = false;
    initFolderShow();
  });
  document.addEventListener("DOMContentLoaded", () => initFolderShow());
