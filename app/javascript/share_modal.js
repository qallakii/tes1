function initShareModal() {
  const modal = document.querySelector("[data-share-modal]");
  if (!modal) return;

  if (window.__shareModalAbort) window.__shareModalAbort.abort();
  window.__shareModalAbort = new AbortController();
  const { signal } = window.__shareModalAbort;

  const expiresInput = modal.querySelector("[data-share-expires]");
  const audienceInputs = Array.from(modal.querySelectorAll("[data-share-audience]"));
  const emailsWrap = modal.querySelector("[data-share-emails-wrap]");
  const emailsInput = modal.querySelector("[data-share-emails]");
  const permissionWrap = modal.querySelector("[data-share-permission-wrap]");
  const permissionInputs = Array.from(modal.querySelectorAll("[data-share-permission]"));
  const existingWrap = modal.querySelector("[data-share-existing-wrap]");
  const existingState = modal.querySelector("[data-share-existing-state]");
  const existingList = modal.querySelector("[data-share-existing-list]");
  const confirmBtn = modal.querySelector("[data-share-confirm]");
  const copyBtn = modal.querySelector("[data-share-copy]");
  const formView = modal.querySelector("[data-share-form-view]");
  const resultView = modal.querySelector("[data-share-result-view]");
  const resultUrl = modal.querySelector("[data-share-result-url]");
  const closeButtons = modal.querySelectorAll("[data-share-close], [data-share-cancel]");

  let currentPayload = null;
  let currentShareUrl = "";
  let detailsRequestId = 0;

  function selectedAudience() {
    const checked = audienceInputs.find((input) => input.checked);
    return checked ? checked.value : "anyone";
  }

  function selectedPermission() {
    const checked = permissionInputs.find((input) => input.checked);
    return checked ? checked.value : "viewer";
  }

  function setSelectedPermission(permission) {
    const next = permissionInputs.find((input) => input.value === permission) || permissionInputs[0];
    if (next) next.checked = true;
  }

  function supportsEditorPermission() {
    return selectedAudience() === "specific_people" && currentPayload && currentPayload.folderIds.length > 0;
  }

  function updateAudienceUI() {
    if (emailsWrap) emailsWrap.hidden = selectedAudience() !== "specific_people";

    if (permissionWrap) permissionWrap.hidden = !supportsEditorPermission();
    if (!supportsEditorPermission()) setSelectedPermission("viewer");
  }

  function resetExistingShares() {
    if (existingList) existingList.innerHTML = "";
    if (existingState) existingState.textContent = "Loading...";
    if (existingWrap) existingWrap.hidden = true;
  }

  function closeModal() {
    modal.hidden = true;
    currentPayload = null;
    currentShareUrl = "";
    detailsRequestId += 1;

    if (expiresInput) expiresInput.value = "";
    if (emailsInput) emailsInput.value = "";
    if (audienceInputs[0]) audienceInputs[0].checked = true;
    setSelectedPermission("viewer");
    if (formView) formView.hidden = false;
    if (resultView) resultView.hidden = true;
    if (confirmBtn) {
      confirmBtn.hidden = false;
      confirmBtn.disabled = false;
      confirmBtn.textContent = "Create share link";
    }
    if (copyBtn) copyBtn.hidden = true;
    resetExistingShares();
    updateAudienceUI();
  }

  function buildParams(payload) {
    const params = new URLSearchParams();

    payload.folderIds.forEach((id) => params.append("folder_ids[]", id));
    payload.cvIds.forEach((id) => params.append("cv_ids[]", id));
    params.append("expires_at", expiresInput ? expiresInput.value : "");
    params.append("share_audience", selectedAudience());
    params.append("share_emails", emailsInput ? emailsInput.value : "");
    params.append("share_permission", selectedPermission());

    return params;
  }

  async function createShareLink(payload) {
    const tokenMeta = document.querySelector('meta[name="csrf-token"]');
    const response = await fetch("/share_links/bulk_create_items", {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
        "X-CSRF-Token": tokenMeta ? tokenMeta.getAttribute("content") : ""
      },
      body: buildParams(payload).toString(),
      credentials: "same-origin"
    });

    if (!response.ok) {
      let message = "Could not create share link.";
      try {
        const data = await response.json();
        if (data && data.error) message = data.error;
      } catch (_error) {
        // Keep default message for non-JSON error responses.
      }
      throw new Error(message);
    }

    return response.json();
  }

  async function fetchSelectionDetails(payload) {
    const tokenMeta = document.querySelector('meta[name="csrf-token"]');
    const response = await fetch("/share_links/selection_details", {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
        "X-CSRF-Token": tokenMeta ? tokenMeta.getAttribute("content") : ""
      },
      body: buildParams(payload).toString(),
      credentials: "same-origin"
    });

    if (!response.ok) throw new Error("Could not load current shares.");
    return response.json();
  }

  function permissionLabel(permission) {
    return permission === "editor" ? "Can edit" : "Can view";
  }

  function renderExistingShares(data) {
    if (!existingWrap || !existingState || !existingList) return;

    const entries = Array.isArray(data?.entries) ? data.entries : [];
    existingWrap.hidden = false;
    existingList.innerHTML = "";

    if (entries.length === 0) {
      existingState.textContent = `${data?.scope_label || "This selection"} is not shared yet.`;
      return;
    }

    existingState.textContent = `${data?.scope_label || "This selection"} is already shared with:`;

    entries.forEach((entry) => {
      const item = document.createElement("li");
      item.className = "share-modal-existing-item";

      const copy = document.createElement("div");
      copy.className = "share-modal-existing-copy";

      const title = document.createElement("div");
      title.className = "share-modal-existing-name";
      title.textContent = entry.kind === "public" ? "Anyone with the link" : (entry.name || entry.label || "Unknown user");
      copy.appendChild(title);

      if (entry.kind === "user" && entry.name && entry.label) {
        const meta = document.createElement("div");
        meta.className = "share-modal-existing-meta";
        meta.textContent = entry.label;
        copy.appendChild(meta);
      }

      const badge = document.createElement("span");
      badge.className = `share-modal-existing-badge ${entry.permission === "editor" ? "is-editor" : "is-viewer"}`;
      badge.textContent = permissionLabel(entry.permission);

      item.appendChild(copy);
      item.appendChild(badge);
      existingList.appendChild(item);
    });
  }

  async function loadExistingShares() {
    const requestId = detailsRequestId + 1;
    detailsRequestId = requestId;

    if (!currentPayload || !existingWrap || !existingState || !existingList) return;

    existingWrap.hidden = false;
    existingList.innerHTML = "";
    existingState.textContent = "Loading...";

    try {
      const data = await fetchSelectionDetails(currentPayload);
      if (requestId !== detailsRequestId) return;
      renderExistingShares(data);
    } catch (_error) {
      if (requestId !== detailsRequestId) return;
      existingList.innerHTML = "";
      existingState.textContent = "Couldn't load current shares.";
    }
  }

  async function copyCurrentLink() {
    if (!currentShareUrl || !copyBtn) return;

    const copy = typeof window.copyTextToClipboard === "function"
      ? window.copyTextToClipboard(currentShareUrl)
      : Promise.resolve(false);

    const copied = await copy;
    if (!copied) return;

    const originalText = copyBtn.textContent;
    copyBtn.textContent = "Copied";
    window.setTimeout(() => {
      copyBtn.textContent = originalText;
    }, 1200);
  }

  function showResult(shareUrl) {
    currentShareUrl = shareUrl;
    if (formView) formView.hidden = true;
    if (resultView) resultView.hidden = false;
    if (resultUrl) {
      resultUrl.href = shareUrl;
      resultUrl.textContent = shareUrl;
    }
    if (confirmBtn) confirmBtn.hidden = true;
    if (copyBtn) copyBtn.hidden = false;
  }

  window.openShareModal = ({ folderIds = [], cvIds = [] }) => {
    if (folderIds.length === 0 && cvIds.length === 0) return;

    currentPayload = {
      folderIds: folderIds.filter(Boolean),
      cvIds: cvIds.filter(Boolean)
    };

    currentShareUrl = "";
    if (formView) formView.hidden = false;
    if (resultView) resultView.hidden = true;
    if (confirmBtn) {
      confirmBtn.hidden = false;
      confirmBtn.disabled = false;
      confirmBtn.textContent = "Create share link";
    }
    if (copyBtn) copyBtn.hidden = true;

    modal.hidden = false;
    updateAudienceUI();
    loadExistingShares();
  };

  audienceInputs.forEach((input) => {
    input.addEventListener("change", updateAudienceUI, { signal });
  });

  closeButtons.forEach((button) => {
    button.addEventListener("click", closeModal, { signal });
  });

  modal.addEventListener("click", (e) => {
    if (e.target === modal) closeModal();
  }, { signal });

  if (confirmBtn) {
    confirmBtn.addEventListener("click", async () => {
      if (!currentPayload) return;
      if (selectedAudience() === "specific_people" && (!emailsInput || emailsInput.value.trim() === "")) {
        window.alert("Enter at least one email address.");
        return;
      }

      confirmBtn.disabled = true;
      confirmBtn.textContent = "Creating...";

      try {
        const data = await createShareLink(currentPayload);
        showResult(data.share_url);
      } catch (error) {
        window.alert(error.message || "Could not create share link.");
        confirmBtn.disabled = false;
        confirmBtn.textContent = "Create share link";
      }
    }, { signal });
  }

  if (copyBtn) copyBtn.addEventListener("click", copyCurrentLink, { signal });

  updateAudienceUI();
}

document.addEventListener("turbo:load", initShareModal);
document.addEventListener("DOMContentLoaded", initShareModal);
document.addEventListener("turbo:before-cache", () => {
  if (window.__shareModalAbort) window.__shareModalAbort.abort();
  window.__shareModalAbort = null;
});
