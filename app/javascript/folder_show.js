function initFolderShowPage() {
  const page = document.querySelector("[data-folder-show]");
  if (!page) return;

  if (window.__folderShowAbort) window.__folderShowAbort.abort();
  window.__folderShowAbort = new AbortController();
  const { signal } = window.__folderShowAbort;

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

  page.querySelectorAll("[data-size-text]").forEach((el) => {
    const raw = parseInt(el.textContent || "0", 10);
    el.textContent = humanSize(raw);
  });

  const previewOverlay = document.getElementById("file-preview-overlay");
  const previewTitle = document.getElementById("file-preview-title");
  const previewDownload = document.getElementById("file-preview-download");
  const previewClose = document.getElementById("file-preview-close");
  const previewFrame = document.getElementById("file-preview-frame");
  const previewVideo = document.getElementById("file-preview-video");
  const previewImage = document.getElementById("file-preview-image");
  const previewAudio = document.getElementById("file-preview-audio");
  const previewFallback = document.getElementById("file-preview-fallback");
  const previewOpenNew = document.getElementById("file-preview-open-new");
  const previewDownloadFallback = document.getElementById("file-preview-download-fallback");
  const previewPrev = document.getElementById("file-preview-prev");
  const previewNext = document.getElementById("file-preview-next");
  const createOverlay = page.querySelector("#create-folder-overlay");
  const openCreateButton = page.querySelector("#open-create-folder");
  const closeCreateButton = page.querySelector("#close-create-folder");
  const cancelCreateButton = page.querySelector("#cancel-create-folder");
  const createInput = page.querySelector(".folder-create-modal-input");
  let activePreviewIndex = -1;

  function previewEntries() {
    return Array.from(page.querySelectorAll(".cv-row.clickable-row"))
      .map((row) => ({
        previewUrl: row.getAttribute("data-preview"),
        downloadUrl: row.getAttribute("data-download"),
        title: row.getAttribute("data-preview-title"),
        contentType: row.getAttribute("data-preview-kind")
      }))
      .filter((entry) => ["image", "video"].includes(previewKind(entry.contentType)) && entry.previewUrl);
  }

  function updatePreviewNavigation() {
    const galleryEntries = previewEntries();
    const hasActiveMedia = activePreviewIndex >= 0 && galleryEntries.length > 0;

    [previewPrev, previewNext].forEach((button) => {
      if (!button) return;
      button.hidden = !hasActiveMedia;
      button.disabled = !hasActiveMedia || galleryEntries.length < 2;
    });
  }

  function hidePreviewNodes() {
    [previewFrame, previewVideo, previewImage, previewAudio, previewFallback].forEach((node) => {
      if (!node) return;
      node.hidden = true;
    });

    if (previewFrame) previewFrame.src = "";
    if (previewVideo) {
      previewVideo.pause();
      previewVideo.removeAttribute("src");
      previewVideo.load();
    }
    if (previewImage) previewImage.removeAttribute("src");
    if (previewAudio) {
      previewAudio.pause();
      previewAudio.removeAttribute("src");
      previewAudio.load();
    }
  }

  function closePreviewModal() {
    hidePreviewNodes();
    activePreviewIndex = -1;
    updatePreviewNavigation();
    if (previewOverlay) previewOverlay.hidden = true;
  }

  function previewKind(contentType) {
    const type = String(contentType || "").toLowerCase();
    if (type.includes("pdf")) return "pdf";
    if (type.startsWith("video/")) return "video";
    if (type.startsWith("image/")) return "image";
    if (type.startsWith("audio/")) return "audio";
    return "fallback";
  }

  function openPreviewModal({ previewUrl, downloadUrl, title, contentType }) {
    if (!previewOverlay || !previewUrl) {
      if (previewUrl) window.open(previewUrl, "_blank", "noopener");
      return;
    }

    const galleryEntries = previewEntries();
    const nextIndex = galleryEntries.findIndex((entry) => entry.previewUrl === previewUrl);
    activePreviewIndex = ["image", "video"].includes(previewKind(contentType)) ? nextIndex : -1;

    hidePreviewNodes();
    if (previewTitle) previewTitle.textContent = title || "File preview";
    if (previewDownload) previewDownload.href = downloadUrl || previewUrl;
    if (previewOpenNew) previewOpenNew.href = previewUrl;
    if (previewDownloadFallback) previewDownloadFallback.href = downloadUrl || previewUrl;

    switch (previewKind(contentType)) {
      case "pdf":
        if (previewFrame) {
          previewFrame.src = previewUrl;
          previewFrame.hidden = false;
        }
        break;
      case "video":
        if (previewVideo) {
          previewVideo.src = previewUrl;
          previewVideo.hidden = false;
        }
        break;
      case "image":
        if (previewImage) {
          previewImage.src = previewUrl;
          previewImage.hidden = false;
        }
        break;
      case "audio":
        if (previewAudio) {
          previewAudio.src = previewUrl;
          previewAudio.hidden = false;
        }
        break;
      default:
        if (previewFallback) previewFallback.hidden = false;
    }

    updatePreviewNavigation();
    previewOverlay.hidden = false;
  }

  function stepPreview(direction) {
    const galleryEntries = previewEntries();
    if (activePreviewIndex < 0 || galleryEntries.length === 0) return;

    const nextIndex = (activePreviewIndex + direction + galleryEntries.length) % galleryEntries.length;
    const nextEntry = galleryEntries[nextIndex];
    if (!nextEntry) return;

    openPreviewModal(nextEntry);
  }

  if (previewClose) previewClose.addEventListener("click", closePreviewModal, { signal });
  if (previewPrev) previewPrev.addEventListener("click", () => stepPreview(-1), { signal });
  if (previewNext) previewNext.addEventListener("click", () => stepPreview(1), { signal });
  if (previewOverlay) {
    previewOverlay.addEventListener("click", (event) => {
      if (event.target === previewOverlay) closePreviewModal();
    }, { signal });
  }

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && previewOverlay && !previewOverlay.hidden) closePreviewModal();
    if (event.key === "ArrowLeft" && previewOverlay && !previewOverlay.hidden) stepPreview(-1);
    if (event.key === "ArrowRight" && previewOverlay && !previewOverlay.hidden) stepPreview(1);
  }, { signal });

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

  function closeAllMenus() {
    document.querySelectorAll("[data-kebab-menu]").forEach((menu) => {
      menu.style.display = "none";
      menu.style.top = "";
      menu.style.left = "";
    });
  }

  function positionMenu(trigger, menu) {
    const triggerRect = trigger.getBoundingClientRect();

    menu.style.position = "fixed";
    menu.style.zIndex = "12000";
    menu.style.display = "block";

    const menuRect = menu.getBoundingClientRect();
    let top = triggerRect.bottom + 8;
    let left = triggerRect.right - menuRect.width;

    if (top + menuRect.height > window.innerHeight - 8) {
      top = triggerRect.top - menuRect.height - 8;
    }

    if (left < 8) left = 8;
    if (left + menuRect.width > window.innerWidth - 8) {
      left = window.innerWidth - menuRect.width - 8;
    }
    if (top < 8) top = 8;

    menu.style.top = `${top}px`;
    menu.style.left = `${left}px`;
  }

  if (window.__folderKebabHandler) {
    document.removeEventListener("click", window.__folderKebabHandler);
    window.__folderKebabHandler = null;
  }

  if (window.__folderKebabKeyHandler) {
    document.removeEventListener("keydown", window.__folderKebabKeyHandler);
    window.__folderKebabKeyHandler = null;
  }

  window.__folderKebabHandler = (e) => {
    const kebabBtn = e.target.closest("[data-kebab]");
    const insideMenu = e.target.closest(".kebab-menu");
    if (insideMenu) return;

    if (!kebabBtn && !insideMenu) {
      closeAllMenus();
      return;
    }

    if (!kebabBtn) return;

    e.preventDefault();
    e.stopPropagation();

    const key = kebabBtn.getAttribute("data-kebab");
    const menu = document.querySelector(`[data-kebab-menu="${key}"]`);
    if (!menu) return;

    const isOpen = menu.style.display === "block";
    closeAllMenus();
    if (isOpen) return;

    if (menu.parentElement !== document.body) {
      document.body.appendChild(menu);
    }

    positionMenu(kebabBtn, menu);
  };

  window.__folderKebabKeyHandler = (e) => {
    if (e.key === "Escape") {
      closeAllMenus();
      closeCreateModal();
    }
  };

  document.addEventListener("click", window.__folderKebabHandler, { signal });
  document.addEventListener("keydown", window.__folderKebabKeyHandler, { signal });
  window.addEventListener("resize", closeAllMenus, { signal });
  window.addEventListener("scroll", closeAllMenus, { signal, capture: true });

  const selectAll = page.querySelector("#select-all");
  const fileChecks = Array.from(page.querySelectorAll(".cv-check"));
  const folderChecks = Array.from(page.querySelectorAll(".folder-check"));

  const bulkBar = page.querySelector("#bulk-actions");
  const openUploadBtn = page.querySelector("#open-upload");
  const uploadOverlay = page.querySelector("#upload-overlay");
  const closeUploadBtn = page.querySelector("#close-upload");
  const cancelUploadBtn = page.querySelector("#cancel-upload");
  const fileInput = page.querySelector("#upload-file-input");
  const chooseFilesBtn = page.querySelector("#choose-files");
  const chooseFolderBtn = page.querySelector("#choose-folder");
  const listWrapCont = page.querySelector("#upload-file-list-wrap");
  const listWrap = page.querySelector("#upload-file-list");
  const folderInput = page.querySelector("#upload-folder-input");
  const uploadSubmitBtn = page.querySelector("#upload-submit");
  const uploadPaths = page.querySelector("#upload-paths");

  function resetUploadList() {
    if (listWrap) listWrap.innerHTML = "";
    if (uploadPaths) uploadPaths.innerHTML = "";
  }

  function setUploadSubmitEnabled(enabled) {
    if (uploadSubmitBtn) uploadSubmitBtn.disabled = !enabled;
  }

  function appendUploadPath(relativePath) {
    if (!uploadPaths || !relativePath) return;

    const input = document.createElement("input");
    input.type = "hidden";
    input.name = "cv[paths][]";
    input.value = relativePath;
    uploadPaths.appendChild(input);
  }

  function showSelectedUploads(files, pathBuilder) {
    resetUploadList();

    const selectedFiles = Array.from(files || []);
    const hasFiles = selectedFiles.length > 0;

    setUploadSubmitEnabled(hasFiles);
    if (listWrapCont) listWrapCont.style.display = hasFiles ? "flex" : "none";

    selectedFiles.forEach((file) => {
      const relativePath = pathBuilder(file);
      const item = document.createElement("li");
      item.textContent = relativePath;
      if (listWrap) listWrap.appendChild(item);
      appendUploadPath(relativePath);
    });
  }

  if (fileInput) {
    fileInput.addEventListener("change", () => {
      showSelectedUploads(fileInput.files, (file) => file.name);
    }, { signal });
  }

  if (openUploadBtn && uploadOverlay) {
    openUploadBtn.addEventListener("click", (e) => {
      e.preventDefault();
      uploadOverlay.style.display = "flex";
    }, { signal });
  }

  if (closeUploadBtn && uploadOverlay) {
    closeUploadBtn.addEventListener("click", () => {
      uploadOverlay.style.display = "none";
    }, { signal });
  }

  if (cancelUploadBtn && uploadOverlay) {
    cancelUploadBtn.addEventListener("click", () => {
      uploadOverlay.style.display = "none";
    }, { signal });
  }

  if (chooseFilesBtn && fileInput) {
    chooseFilesBtn.addEventListener("click", () => {
      fileInput.click();
    }, { signal });
  }

  if (chooseFolderBtn && folderInput) {
    chooseFolderBtn.addEventListener("click", () => {
      folderInput.click();
    }, { signal });
  }

  if (folderInput) {
    folderInput.addEventListener("change", () => {
      showSelectedUploads(folderInput.files, (file) => file.webkitRelativePath || file.name);
    }, { signal });
  }

  folderChecks.forEach((cb) => cb.addEventListener("click", (e) => e.stopPropagation(), { signal }));
  fileChecks.forEach((cb) => cb.addEventListener("click", (e) => e.stopPropagation(), { signal }));

  function selectedFileIds() {
    return fileChecks.filter((checkbox) => checkbox.checked).map((checkbox) => checkbox.value);
  }

  function selectedFolderIds() {
    return folderChecks
      .filter((checkbox) => checkbox.checked)
      .map((checkbox) => checkbox.value)
      .filter(Boolean);
  }

  function updateBulk() {
    const any = selectedFileIds().length > 0 || selectedFolderIds().length > 0;
    if (bulkBar) bulkBar.style.display = any ? "inline-flex" : "none";
    if (openUploadBtn) openUploadBtn.style.display = any ? "none" : "";
    if (openCreateButton) openCreateButton.style.display = any ? "none" : "";

    if (selectAll) {
      const all = [...fileChecks, ...folderChecks];
      selectAll.checked = all.length > 0 && all.every((checkbox) => checkbox.checked);
    }
  }

  if (selectAll) {
    selectAll.addEventListener("change", () => {
      const checked = selectAll.checked;
      fileChecks.forEach((checkbox) => {
        checkbox.checked = checked;
      });
      folderChecks.forEach((checkbox) => {
        checkbox.checked = checked;
      });
      updateBulk();
    }, { signal });
  }

  fileChecks.forEach((checkbox) => checkbox.addEventListener("change", updateBulk, { signal }));
  folderChecks.forEach((checkbox) => checkbox.addEventListener("change", updateBulk, { signal }));
  updateBulk();

  page.querySelectorAll(".clickable-folder").forEach((row) => {
    const url = row.getAttribute("data-folder-url");

    row.addEventListener("click", (e) => {
      if (e.target.closest(".kebab-wrap")) return;
      if (e.target.closest("a, button, input, label, form")) return;
      if (e.target.closest(".col-cv-actions")) return;
      if (url) window.location.href = url;
    }, { signal });
  });

  page.querySelectorAll(".cv-row.clickable-row").forEach((row) => {
    row.addEventListener("click", (e) => {
      if (e.target.closest(".kebab-wrap")) return;
      if (e.target.closest("a, button, input, label, form")) return;
      if (e.target.closest(".col-cv-actions")) return;

      openPreviewModal({
        previewUrl: row.getAttribute("data-preview"),
        downloadUrl: row.getAttribute("data-download"),
        title: row.getAttribute("data-preview-title"),
        contentType: row.getAttribute("data-preview-kind")
      });
    }, { signal });
  });

  page.querySelectorAll(".preview-file-btn").forEach((button) => {
    button.addEventListener("click", (event) => {
      event.preventDefault();
      openPreviewModal({
        previewUrl: button.dataset.preview,
        downloadUrl: button.dataset.download,
        title: button.dataset.previewTitle,
        contentType: button.dataset.previewKind
      });
    }, { signal });
  });

  function fillHiddenInputs(container, name, values) {
    if (!container) return;
    container.innerHTML = "";

    values.forEach((value) => {
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = name;
      input.value = value;
      container.appendChild(input);
    });
  }

  const bulkDownloadBtn = page.querySelector("#bulk-download");
  const bulkDownloadForm = page.querySelector("#bulk-download-form");
  const bulkDownloadFolderIds = page.querySelector("#bulk-download-folder-ids");
  const bulkDownloadFileIds = page.querySelector("#bulk-download-file-ids");

  if (bulkDownloadBtn && bulkDownloadForm) {
    bulkDownloadBtn.addEventListener("click", (e) => {
      e.preventDefault();

      const folderIds = selectedFolderIds();
      const fileIds = selectedFileIds();

      if (folderIds.length === 0 && fileIds.length === 0) return;

      fillHiddenInputs(bulkDownloadFolderIds, "folder_ids[]", folderIds);
      fillHiddenInputs(bulkDownloadFileIds, "cv_ids[]", fileIds);
      bulkDownloadForm.submit();
    }, { signal });
  }

  const renameOverlay = page.querySelector("#rename-folder-overlay");
  const renameInput = page.querySelector("#rename-folder-input");
  const renameForm = page.querySelector("#rename-folder-form");
  const closeRename = page.querySelector("#close-rename-folder");
  const cancelRename = page.querySelector("#cancel-rename-folder");

  function openRenameModal(folderId, folderName) {
    if (!renameOverlay || !renameForm || !renameInput) return;

    renameInput.value = folderName || "";
    const prefix = renameForm.dataset.renamePrefix || "/folders";
    renameForm.action = `${prefix}/${folderId}/rename`;
    renameOverlay.style.display = "flex";
    renameInput.focus();
    renameInput.select();
  }

  function closeRenameModal() {
    if (renameOverlay) renameOverlay.style.display = "none";
  }

  page.querySelectorAll(".folder-rename-btn").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      openRenameModal(btn.dataset.folderId, btn.dataset.folderName);
    }, { signal });
  });

  if (closeRename) closeRename.addEventListener("click", closeRenameModal, { signal });
  if (cancelRename) cancelRename.addEventListener("click", closeRenameModal, { signal });
  if (renameOverlay) {
    renameOverlay.addEventListener("click", (e) => {
      if (e.target === renameOverlay) closeRenameModal();
    }, { signal });
  }

  const bulkDeleteBtn = page.querySelector("#bulk-delete");
  const bulkDestroyForm = page.querySelector("#bulk-destroy-items-form");
  const bulkDestroyFolderIds = page.querySelector("#bulk-destroy-folder-ids");
  const bulkDestroyFileIds = page.querySelector("#bulk-destroy-file-ids");

  if (bulkDeleteBtn && bulkDestroyForm) {
    bulkDeleteBtn.addEventListener("click", (e) => {
      e.preventDefault();

      const folderIds = selectedFolderIds();
      const fileIds = selectedFileIds();

      if (folderIds.length === 0 && fileIds.length === 0) return;
      if (!window.confirm("Delete selected items?")) return;

      fillHiddenInputs(bulkDestroyFolderIds, "folder_ids[]", folderIds);
      fillHiddenInputs(bulkDestroyFileIds, "cv_ids[]", fileIds);
      bulkDestroyForm.submit();
    }, { signal });
  }

  const moveOverlay = page.querySelector("#move-overlay");
  const moveSelectedName = page.querySelector("#move-selected-name");
  const moveConfirm = page.querySelector("#move-confirm");
  const moveCancel = page.querySelector("#move-cancel");
  const closeMove = page.querySelector("#close-move");
  const bulkMoveForm = page.querySelector("#bulk-move-form");
  const bulkMoveFolderIds = page.querySelector("#bulk-move-folder-ids");
  const bulkMoveFileIds = page.querySelector("#bulk-move-file-ids");
  const moveTarget = page.querySelector("#move-target-folder-id");
  const moveOneForm = page.querySelector("#move-one-form");
  const moveOneFolderId = page.querySelector("#move-one-folder-id");
  const moveOneFileId = page.querySelector("#move-one-file-id");
  const moveTargetOne = page.querySelector("#move-target-folder-id-one");

  let pickedTargetId = null;
  let moveMode = "bulk";
  let oneFolderId = null;
  let oneCvId = null;

  function openMoveModal(mode, itemId = null) {
    if (!moveOverlay) return;

    moveMode = mode;
    oneFolderId = mode === "one-folder" ? itemId : null;
    oneCvId = mode === "one-file" ? itemId : null;
    pickedTargetId = null;

    if (moveSelectedName) moveSelectedName.textContent = "None";
    if (moveConfirm) moveConfirm.disabled = true;

    page.querySelectorAll(".tree-row").forEach((row) => {
      row.classList.remove("selected");
    });

    moveOverlay.style.display = "flex";
  }

  function closeMoveModal() {
    if (moveOverlay) moveOverlay.style.display = "none";
  }

  page.querySelectorAll(".tree-row").forEach((row) => {
    const pick = row.querySelector(".tree-pick");
    const toggle = row.querySelector(".tree-toggle");
    const next = row.nextElementSibling;

    if (toggle && next && next.classList.contains("tree-children")) {
      toggle.addEventListener("click", (e) => {
        e.preventDefault();
        const open = next.style.display === "block";
        next.style.display = open ? "none" : "block";
        toggle.textContent = open ? "▸" : "▾";
      }, { signal });
    }

    if (pick) {
      pick.addEventListener("click", (e) => {
        e.preventDefault();
        pickedTargetId = row.dataset.folderId;

        page.querySelectorAll(".tree-row").forEach((treeRow) => {
          treeRow.classList.remove("selected");
        });
        row.classList.add("selected");

        if (moveSelectedName) moveSelectedName.textContent = row.dataset.folderName || "Selected";
        if (moveConfirm) moveConfirm.disabled = !pickedTargetId;
      }, { signal });
    }
  });

  const bulkMoveBtn = page.querySelector("#bulk-move");
  if (bulkMoveBtn) {
    bulkMoveBtn.addEventListener("click", (e) => {
      e.preventDefault();
      const any = selectedFolderIds().length > 0 || selectedFileIds().length > 0;
      if (!any) return;
      openMoveModal("bulk");
    }, { signal });
  }

  page.querySelectorAll(".move-one-btn").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      openMoveModal("one-file", btn.dataset.cvId);
    }, { signal });
  });

  page.querySelectorAll(".move-folder-btn").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      openMoveModal("one-folder", btn.dataset.folderId);
    }, { signal });
  });

  if (moveCancel) moveCancel.addEventListener("click", closeMoveModal, { signal });
  if (closeMove) closeMove.addEventListener("click", closeMoveModal, { signal });
  if (moveOverlay) {
    moveOverlay.addEventListener("click", (e) => {
      if (e.target === moveOverlay) closeMoveModal();
    }, { signal });
  }

  if (moveConfirm) {
    moveConfirm.addEventListener("click", (e) => {
      e.preventDefault();
      if (!pickedTargetId) return;

      if (moveMode === "bulk") {
        if (!bulkMoveForm || !moveTarget) return;

        moveTarget.value = pickedTargetId;
        fillHiddenInputs(bulkMoveFolderIds, "folder_ids[]", selectedFolderIds());
        fillHiddenInputs(bulkMoveFileIds, "cv_ids[]", selectedFileIds());
        bulkMoveForm.submit();
        closeMoveModal();
        return;
      }

      if (moveMode === "one-file" || moveMode === "one-folder") {
        if (!moveOneForm || !moveTargetOne || !moveOneFileId || !moveOneFolderId) return;

        moveTargetOne.value = pickedTargetId;
        fillHiddenInputs(moveOneFolderId, "folder_ids[]", oneFolderId ? [oneFolderId] : []);
        fillHiddenInputs(moveOneFileId, "cv_ids[]", oneCvId ? [oneCvId] : []);
        moveOneForm.submit();
        closeMoveModal();
      }
    }, { signal });
  }

  page.querySelectorAll(".share-one-btn").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      if (typeof window.openShareModal === "function") {
        window.openShareModal({ folderIds: [], cvIds: [btn.dataset.cvId] });
      }
    }, { signal });
  });

  const bulkShareBtn = page.querySelector("#bulk-share");
  if (bulkShareBtn) {
    bulkShareBtn.addEventListener("click", (e) => {
      e.preventDefault();

      const folderIds = selectedFolderIds();
      const fileIds = selectedFileIds();

      if (folderIds.length === 0 && fileIds.length === 0) return;
      if (typeof window.openShareModal === "function") {
        window.openShareModal({ folderIds, cvIds: fileIds });
      }
    }, { signal });
  }
}

document.addEventListener("turbo:load", initFolderShowPage);
document.addEventListener("DOMContentLoaded", initFolderShowPage);

document.addEventListener("turbo:before-cache", () => {
  if (window.__folderShowAbort) window.__folderShowAbort.abort();
  window.__folderShowAbort = null;

  document.querySelectorAll("[data-kebab-menu]").forEach((menu) => {
    menu.style.display = "none";
    menu.style.top = "";
    menu.style.left = "";
  });

  const createOverlay = document.getElementById("create-folder-overlay");
  if (createOverlay) createOverlay.style.display = "none";

  const previewOverlay = document.getElementById("file-preview-overlay");
  if (previewOverlay) previewOverlay.hidden = true;
});
