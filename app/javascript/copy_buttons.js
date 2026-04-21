async function copyTextToClipboard(text) {
  if (!text) return false;

  try {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch (_error) {
    // Fall through to the legacy copy path.
  }

  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.setAttribute("readonly", "");
  textarea.style.position = "fixed";
  textarea.style.top = "-9999px";
  textarea.style.left = "-9999px";
  textarea.style.opacity = "0";
  document.body.appendChild(textarea);
  textarea.focus();
  textarea.select();

  let copied = false;
  try {
    copied = document.execCommand("copy");
  } catch (_error) {
    copied = false;
  }

  document.body.removeChild(textarea);

  if (copied) return true;

  window.prompt("Copy this link:", text);
  return false;
}

window.copyTextToClipboard = copyTextToClipboard;

function initCopyButtons() {
  if (window.__copyButtonsBound) return;
  window.__copyButtonsBound = true;

  document.addEventListener("click", async (e) => {
    const button = e.target.closest("[data-copy]");
    if (!button) return;

    const text = button.getAttribute("data-copy");
    if (!text) return;

    const copied = await copyTextToClipboard(text);
    if (!copied) return;

    const originalText = button.textContent;
    button.textContent = "Copied";
    window.setTimeout(() => {
      button.textContent = originalText;
    }, 1200);
  });
}

document.addEventListener("turbo:load", initCopyButtons);
document.addEventListener("DOMContentLoaded", initCopyButtons);
