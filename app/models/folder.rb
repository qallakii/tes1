class Folder < ApplicationRecord
  belongs_to :user
  has_many :cvs, dependent: :destroy

  # ✅ nesting
  belongs_to :parent, class_name: "Folder", optional: true
  has_many :subfolders, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy

  validate :nesting_depth_within_limit

  MAX_DEPTH = 5

  # depth: root folder = 1, child = 2, etc.
  def depth
    d = 1
    node = self
    while node.parent
      d += 1
      node = node.parent
      break if d > 50 # safety
    end
    d
  end

  # Home / A / B / C path helpers (for breadcrumbs)
  def ancestors
    list = []
    node = self.parent
    while node
      list.unshift(node)
      node = node.parent
      break if list.length > 50
    end
    list
  end

  private

  def nesting_depth_within_limit
    # If parent is nil => root folder => ok
    return if parent.nil?

    # parent depth + this folder = resulting depth
    if parent.depth + 1 > MAX_DEPTH
      errors.add(:parent_id, "Maximum folder depth is #{MAX_DEPTH}.")
    end

    # prevent loops
    if parent_id.present? && parent_id == id
      errors.add(:parent_id, "cannot be itself")
    end
  end
end
