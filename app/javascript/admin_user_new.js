function initAdminUserNewPage() {
  const page = document.querySelector("[data-admin-user-new]");
  if (!page) return;

  const radios = Array.from(page.querySelectorAll('input[name="password_mode"]'));
  const panels = Array.from(page.querySelectorAll("[data-password-panel]"));
  if (radios.length === 0 || panels.length === 0) return;

  function selectedMode() {
    return radios.find((radio) => radio.checked)?.value || "password";
  }

  function updatePanels() {
    const mode = selectedMode();
    panels.forEach((panel) => {
      panel.hidden = panel.dataset.passwordPanel !== mode;
    });
  }

  radios.forEach((radio) => {
    radio.addEventListener("change", updatePanels);
  });

  updatePanels();
}

document.addEventListener("turbo:load", initAdminUserNewPage);
