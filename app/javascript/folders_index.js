function csrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]')
  return meta ? meta.getAttribute("content") : ""
}

function buildHiddenInputs(container, ids) {
  container.innerHTML = ""
  ids.forEach((id) => {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = "folder_ids[]"
    input.value = id
    container.appendChild(input)
  })
}

function setupFolderIndex() {
  const rows = document.querySelectorAll("[data-folder-row]")
  if (!rows.length) return

  const bulkbar = document.getElementById("folder-bulkbar")
  const countEl = document.getElementById("folder-selected-count")
  const inputsWrap = document.getElementById("folder-selected-inputs")
  const selectAllBtn = document.getElementById("folder-select-all")
  const clearBtn = document.getElementById("folder-clear")

  const checkboxes = () => Array.from(document.querySelectorAll("[data-folder-checkbox]"))
  const selectedIds = () => checkboxes().filter((c) => c.checked).map((c) => c.value)

  function update() {
    const ids = selectedIds()
    if (bulkbar) bulkbar.classList.toggle("show", ids.length > 0)
    if (countEl) countEl.textContent = String(ids.length)
    if (inputsWrap) buildHiddenInputs(inputsWrap, ids)
  }

  rows.forEach((row) => {
    row.addEventListener("click", (e) => {
      if (e.target.closest("input") || e.target.closest("button") || e.target.closest("a")) return
      const href = row.getAttribute("data-href")
      if (href) window.location.href = href
    })
  })

  checkboxes().forEach((cb) => cb.addEventListener("change", update))

  if (selectAllBtn) {
    selectAllBtn.addEventListener("click", () => {
      const all = checkboxes()
      const anyUnchecked = all.some((c) => !c.checked)
      all.forEach((c) => (c.checked = anyUnchecked))
      update()
    })
  }

  if (clearBtn) {
    clearBtn.addEventListener("click", () => {
      checkboxes().forEach((c) => (c.checked = false))
      update()
    })
  }

  document.querySelectorAll("[data-rename-folder]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-folder-id")
      const current = btn.getAttribute("data-current-name") || ""
      const name = window.prompt("New folder name:", current)
      if (!name) return

      const form = document.createElement("form")
      form.method = "post"
      form.action = `/folders/${id}`

      const method = document.createElement("input")
      method.type = "hidden"
      method.name = "_method"
      method.value = "patch"

      const token = document.createElement("input")
      token.type = "hidden"
      token.name = "authenticity_token"
      token.value = csrfToken()

      const field = document.createElement("input")
      field.type = "hidden"
      field.name = "folder[name]"
      field.value = name

      form.appendChild(method)
      form.appendChild(token)
      form.appendChild(field)
      document.body.appendChild(form)
      form.submit()
    })
  })

  update()
}

document.addEventListener("turbo:load", setupFolderIndex)
