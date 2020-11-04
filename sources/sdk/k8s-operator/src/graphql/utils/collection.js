const sort = (items, { key, reversed = false }) => {
  const sorted = items.slice().sort((item, other) =>
    item[key] - other[key]
  )

  if (reversed) {
    sorted.reverse()
  }

  return sorted
}

const pagination = (items, { offset = 0, limit = Number.MAX_SAFE_INTEGER }) =>
  items.slice(offset).slice(0, limit)

const collection = (parent, { paging, sorting }) =>
  pagination(
    sorting ? sort(parent.items, sorting) : parent.items,
    paging
  )

module.exports = {
  sort,
  pagination,
  collection
}
