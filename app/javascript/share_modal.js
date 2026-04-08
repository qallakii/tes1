function initShareModal() {
  const modal = document.querySelector("[data-share-modal]");
  if (!modal) return;

  const expiresInput = modal.querySelector("[data-share-expires]");
  const audienceInputs = Array.from(modal.querySelectorAll("[data-share-audience]"));
  const emailsWrap = modal.querySelector("[data-share-emails-wrap]");
  const emailsInput = modal.querySelector("[data-share-emails]");
  const confirmBtn = modal.querySelector("[data-share-confirm]");
  const copyBtn = modal.querySelector("[data-share-copy]");
  const formView = modal.querySelector("[data-share-form-view]");
  const resultView = modal.querySelector("[data-share-result-view]");
  const resultUrl = modal.querySelector("[data-share-result-url]");
  const closeButtons = modal.querySelectorAll("[data-share-close], [data-share-cancel]");

  let currentPayload = null;
  let currentShareUrl = "";

  function selectedAudience() {
    const checked = audienceInputs.find((input) => input.checked);
    return checked ? checked.value : "anyone";
  }

  function updateAudienceUI() {
    if (!emailsWrap) return;
    emailsWrap.style.display = selectedAudience() === "specific_people" ? "block" : "none";
  }

  function closeModal() {
    modal.style.display = "none";
    currentPayload = null;
    currentShareUrl = "";
    if (expiresInput) expiresInput.value = "";
    if (emailsInput) emailsInput.value = "";
    if (audienceInputs[0]) audienceInputs[0].checked = true;
    if (formView) formView.style.display = "block";
    if (resultView) resultView.style.display = "none";
    if (confirmBtn) {
      confirmBtn.style.display = "";
      confirmBtn.disabled = false;
      confirmBtn.textContent = "Create share link";
    }
    if (copyBtn) {
      copyBtn.style.display = "none";
    }
    updateAudienceUI();
  }

  async function createShareLink(payload) {
    const tokenMeta = document.querySelector('meta[name="csrf-token"]');
    const params = new URLSearchParams();

    payload.folderIds.forEach((id) => params.append("folder_ids[]", id));
    payload.cvIds.forEach((id) => params.append("cv_ids[]", id));
    params.append("expires_at", expiresInput ? expiresInput.value : "");
    params.append("share_audience", selectedAudience());
    params.append("share_emails", emailsInput ? emailsInput.value : "");

    const response = await fetch("/share_links/bulk_create_items", {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
        "X-CSRF-Token": tokenMeta ? tokenMeta.getAttribute("content") : ""
      },
      body: params.toString(),
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

  async function copyCurrentLink() {
    if (!currentShareUrl) return;

    try {
      await navigator.clipboard.writeText(currentShareUrl);
      if (!copyBtn) return;
      const originalText = copyBtn.textContent;
      copyBtn.textContent = "Copied";
      window.setTimeout(() => {
        copyBtn.textContent = originalText;
      }, 1200);
    } catch (_error) {
      window.alert("Copy failed. Please copy the link manually.");
    }
  }

  function showResult(shareUrl) {
    currentShareUrl = shareUrl;
    if (formView) formView.style.display = "none";
    if (resultView) resultView.style.display = "block";
    if (resultUrl) {
      resultUrl.href = shareUrl;
      resultUrl.textContent = shareUrl;
    }
    if (confirmBtn) confirmBtn.style.display = "none";
    if (copyBtn) {
      copyBtn.style.display = "";
    }
  }

  window.openShareModal = ({ folderIds = [], cvIds = [] }) => {
    if (folderIds.length === 0 && cvIds.length === 0) return;

    currentPayload = {
      folderIds: folderIds.filter(Boolean),
      cvIds: cvIds.filter(Boolean)
    };

    modal.style.display = "flex";
    updateAudienceUI();
  };

  audienceInputs.forEach((input) => {
    input.addEventListener("change", updateAudienceUI);
  });

  closeButtons.forEach((button) => {
    button.addEventListener("click", closeModal);
  });

  modal.addEventListener("click", (e) => {
    if (e.target === modal) closeModal();
  });

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
    });
  }

  if (copyBtn) {
    copyBtn.addEventListener("click", copyCurrentLink);
  }

  updateAudienceUI();
}

document.addEventListener("turbo:load", initShareModal);
document.addEventListener("DOMContentLoaded", initShareModal);
