class Folder < ApplicationRecord
  belongs_to :user

  has_many :cvs, dependent: :destroy
  has_many :share_link_folders, dependent: :destroy
  has_many :share_links, through: :share_link_folders

  # nesting
  belongs_to :parent, class_name: "Folder", optional: true
  has_many :subfolders, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy

  MAX_DEPTH = 5

  validate :nesting_depth_within_limit
  validate :parent_belongs_to_same_user

  # depth: root folder = 1, child = 2, etc.
  def depth
    d = 1
    node = self
    while node&.parent
      d += 1
      node = node.parent
      break if d > 50 # safety
    end
    d
  end

  def self_and_descendant_ids
    ids = [id]
    queue = [self]
    while queue.any?
      node = queue.shift
      kids = node.subfolders.to_a
      ids.concat(kids.map(&:id))
      queue.concat(kids)
    end
    ids.uniq
  end

  def recalc_bytes_cached!
    total = 0

    Folder.where(id: self_and_descendant_ids).includes(cvs: { file_attachment: :blob }).find_each do |f|
      f.cvs.each do |cv|
        total += cv.file.blob.byte_size if cv.file.attached?
      end
    end

    update!(bytes_cached: total)
    total
  end


  # Home / A / B / C path helpers (for breadcrumbs)
  def ancestors
    list = []
    node = parent
    while node
      list.unshift(node)
      node = node.parent
      break if list.length > 50
    end
    list
  end

  # ✅ REQUIRED by controllers:
  # returns [self.id, child.id, grandchild.id...] for THIS USER ONLY
  def self_and_descendant_ids(limit: 10_000)
    ids = []
    queue = [id]
    seen = {}

    while queue.any?
      break if ids.length >= limit

      current_id = queue.shift
      next if seen[current_id]
      seen[current_id] = true

      ids << current_id

      child_ids = Folder.where(user_id: user_id, parent_id: current_id).pluck(:id)
      queue.concat(child_ids)
    end

    ids
  end

  def descendant_ids(limit: 10_000)
    self_and_descendant_ids(limit: limit) - [id]
  end

  private

  def nesting_depth_within_limit
    return if parent.nil?

    if parent.depth + 1 > MAX_DEPTH
      errors.add(:parent_id, "Maximum folder depth is #{MAX_DEPTH}.")
    end

    # prevent loops (self-parent)
    if parent_id.present? && parent_id == id
      errors.add(:parent_id, "cannot be itself")
    end
  end

  # ✅ Critical hardening: you can NEVER attach your folder under another user's folder
  def parent_belongs_to_same_user
    return if parent.nil?
    if parent.user_id != user_id
      errors.add(:parent_id, "must belong to the same user")
    end
  end
end
