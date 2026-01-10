let openMenu = null
let openTrigger = null

function closeMenu() {
  if (!openMenu) return
  openMenu.classList.add("hidden")
  openMenu = null
  openTrigger = null
}

function positionMenu(trigger, menu) {
  const r = trigger.getBoundingClientRect()

  menu.style.position = "fixed"
  menu.style.zIndex = "99999"

  // show temporarily to measure
  menu.classList.remove("hidden")
  const mr = menu.getBoundingClientRect()

  // Prefer open downward, but flip if near bottom
  let top = r.bottom + 8
  let left = r.right - mr.width

  if (top + mr.height > window.innerHeight - 8) {
    top = r.top - mr.height - 8
  }
  if (left < 8) left = 8
  if (left + mr.width > window.innerWidth - 8) left = window.innerWidth - mr.width - 8
  if (top < 8) top = 8

  menu.style.top = `${top}px`
  menu.style.left = `${left}px`
}

function openActionMenu(trigger) {
  const menuId = trigger.getAttribute("data-menu-id")
  if (!menuId) return

  const menu = document.getElementById(menuId)
  if (!menu) return

  // toggle same menu
  if (openMenu === menu && !menu.classList.contains("hidden")) {
    closeMenu()
    return
  }

  // close other
  closeMenu()

  // Move to body so it won't be clipped
  if (menu.parentElement !== document.body) document.body.appendChild(menu)

  openMenu = menu
  openTrigger = trigger
  positionMenu(trigger, menu)
}

export function initActionsMenus() {
  // prevent multiple bindings across turbo
  if (document.body.dataset.actionsMenusBound === "true") return
  document.body.dataset.actionsMenusBound = "true"

  document.addEventListener("click", (e) => {
    const trigger = e.target.closest("[data-action-menu-trigger='true']")
    if (trigger) {
      e.preventDefault()
      e.stopPropagation()
      openActionMenu(trigger)
      return
    }

    // click outside closes
    if (openMenu && !openMenu.contains(e.target)) closeMenu()
  })

  window.addEventListener("resize", () => {
    if (openMenu && openTrigger) positionMenu(openTrigger, openMenu)
  })

  window.addEventListener("scroll", () => {
    if (openMenu && openTrigger) positionMenu(openTrigger, openMenu)
  }, true)

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeMenu()
  })
}
