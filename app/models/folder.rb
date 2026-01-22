class Folder < ApplicationRecord
  belongs_to :user
  has_many :cvs, dependent: :destroy
  has_many :share_link_folders, dependent: :destroy
  has_many :share_links, through: :share_link_folders

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

    # ✅ ids of self + all descendants (BFS; safe against deep chains)
  def self_and_descendant_ids
    ids = [id]
    frontier = [id]

    while frontier.any?
      child_ids = Folder.where(parent_id: frontier).pluck(:id)
      break if child_ids.empty?

      ids.concat(child_ids)
      frontier = child_ids
    end

    ids.uniq
  end

  def descendant_ids
    self_and_descendant_ids - [id]
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
