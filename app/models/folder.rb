class Folder < ApplicationRecord
  belongs_to :user
  has_many :cvs, dependent: :destroy
  has_many :share_link_folders, dependent: :destroy
  has_many :share_links, through: :share_link_folders

  belongs_to :parent, class_name: "Folder", optional: true
  has_many :subfolders, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy

  validate :nesting_depth_within_limit

  MAX_DEPTH = 5

  def depth
    d = 1
    node = self
    while node.parent
      d += 1
      node = node.parent
      break if d > 50
    end
    d
  end

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

  # ✅ REQUIRED by your controller:
  # returns [self.id, child.id, grandchild.id...]
  def self_and_descendant_ids(limit: 10_000)
    ids = []
    queue = [self.id]
    seen = {}

    while queue.any?
      break if ids.length >= limit

      current_id = queue.shift
      next if seen[current_id]
      seen[current_id] = true

      ids << current_id

      Folder.where(parent_id: current_id).pluck(:id).each do |child_id|
        queue << child_id
      end
    end

    ids
  end

  def descendant_ids(limit: 10_000)
    self_and_descendant_ids(limit: limit) - [self.id]
  end

  private

  def nesting_depth_within_limit
    return if parent.nil?

    if parent.depth + 1 > MAX_DEPTH
      errors.add(:parent_id, "Maximum folder depth is #{MAX_DEPTH}.")
    end

    if parent_id.present? && parent_id == id
      errors.add(:parent_id, "cannot be itself")
    end
  end
end
