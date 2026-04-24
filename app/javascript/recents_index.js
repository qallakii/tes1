function initRecentsIndexPage() {
  const page = document.querySelector("[data-recents-index]");
  if (!page) return;

  if (window.__recentsIndexAbort) window.__recentsIndexAbort.abort();
  window.__recentsIndexAbort = new AbortController();
  const { signal } = window.__recentsIndexAbort;

  const searchInput = page.querySelector("#recent-search");
  const rows = Array.from(page.querySelectorAll(".recent-row"));
  const noResults = page.querySelector("#recent-no-results");
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
  const renameFileOverlay = page.querySelector("#rename-file-overlay");
  const renameFileInput = page.querySelector("#rename-file-input");
  const renameFileForm = page.querySelector("#rename-file-form");
  const closeRenameFile = page.querySelector("#close-rename-file");
  const cancelRenameFile = page.querySelector("#cancel-rename-file");

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

    previewOverlay.hidden = false;
  }

  function openRenameFileModal(renameUrl, fileName) {
    if (!renameFileOverlay || !renameFileForm || !renameFileInput || !renameUrl) return;

    renameFileInput.value = fileName || "";
    renameFileForm.action = renameUrl;
    renameFileOverlay.style.display = "flex";
    renameFileInput.focus();
    renameFileInput.select();
  }

  function closeRenameFileModal() {
    if (renameFileOverlay) renameFileOverlay.style.display = "none";
  }

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

  rows.forEach((row) => {
    row.addEventListener("click", (event) => {
      if (event.target.closest("a, button, input, label, form")) return;
      if (event.target.closest(".col-actions")) return;

      openPreviewModal({
        previewUrl: row.dataset.preview,
        downloadUrl: row.dataset.download,
        title: row.dataset.previewTitle,
        contentType: row.dataset.previewKind
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

  page.querySelectorAll(".file-rename-btn").forEach((button) => {
    button.addEventListener("click", (event) => {
      event.preventDefault();
      openRenameFileModal(button.dataset.renameUrl, button.dataset.fileName);
    }, { signal });
  });

  if (previewClose) previewClose.addEventListener("click", closePreviewModal, { signal });
  if (closeRenameFile) closeRenameFile.addEventListener("click", closeRenameFileModal, { signal });
  if (cancelRenameFile) cancelRenameFile.addEventListener("click", closeRenameFileModal, { signal });
  if (previewOverlay) {
    previewOverlay.addEventListener("click", (event) => {
      if (event.target === previewOverlay) closePreviewModal();
    }, { signal });
  }
  if (renameFileOverlay) {
    renameFileOverlay.addEventListener("click", (event) => {
      if (event.target === renameFileOverlay) closeRenameFileModal();
    }, { signal });
  }

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && previewOverlay && !previewOverlay.hidden) closePreviewModal();
    if (event.key === "Escape" && renameFileOverlay && renameFileOverlay.style.display === "flex") {
      closeRenameFileModal();
    }
  }, { signal });

  if (searchInput) searchInput.addEventListener("input", applyFilters, { signal });

  document.addEventListener("turbo:before-cache", () => {
    if (window.__recentsIndexAbort) window.__recentsIndexAbort.abort();
    window.__recentsIndexAbort = null;
    if (previewOverlay) previewOverlay.hidden = true;
    if (renameFileOverlay) renameFileOverlay.style.display = "none";
    hidePreviewNodes();
  }, { signal, once: true });

  applyFilters();
}

document.addEventListener("turbo:load", initRecentsIndexPage);
