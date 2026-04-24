function initMobileNav() {
  const nav = document.querySelector("[data-mobile-nav]");
  const toggle = document.querySelector("[data-mobile-nav-toggle]");
  const panel = document.getElementById("driveMobileNavPanel");
  const closeButtons = document.querySelectorAll("[data-mobile-nav-close]");

  if (!nav || !toggle || !panel) return;
  if (window.__mobileNavAbort) window.__mobileNavAbort.abort();
  window.__mobileNavAbort = new AbortController();
  const { signal } = window.__mobileNavAbort;

  const openNav = () => {
    nav.classList.add("is-open");
    document.body.classList.add("mobile-nav-open");
    toggle.setAttribute("aria-expanded", "true");
    panel.setAttribute("aria-hidden", "false");
  };

  const closeNav = () => {
    nav.classList.remove("is-open");
    document.body.classList.remove("mobile-nav-open");
    toggle.setAttribute("aria-expanded", "false");
    panel.setAttribute("aria-hidden", "true");
  };

  toggle.addEventListener("click", (event) => {
    event.preventDefault();
    if (nav.classList.contains("is-open")) {
      closeNav();
    } else {
      openNav();
    }
  }, { signal });

  closeButtons.forEach((button) => {
    button.addEventListener("click", closeNav, { signal });
  });

  nav.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", closeNav, { signal });
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeNav();
  }, { signal });

  document.addEventListener("turbo:before-cache", () => {
    closeNav();
    if (window.__mobileNavAbort) {
      window.__mobileNavAbort.abort();
      window.__mobileNavAbort = null;
    }
  }, { signal, once: true });

  window.addEventListener("resize", () => {
    if (window.innerWidth > 700) closeNav();
  }, { signal });
}

document.addEventListener("turbo:load", initMobileNav);
document.addEventListener("DOMContentLoaded", initMobileNav);
