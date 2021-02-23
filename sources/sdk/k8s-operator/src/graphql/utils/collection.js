const sort = (items, { key, reversed = false }) => {
  const sorted = items.slice().sort((item, other) => {
    if (item[key] > other[key]) {
      return 1
    }
    else if (item[key] < other[key]) {
      return -1
    }
    return 0
  })

  if (reversed) {
    sorted.reverse()
  }

  return sorted
}

const pagination = (items, { offset = 0, limit = Number.MAX_SAFE_INTEGER }) =>
  items.slice(offset).slice(0, limit)

const collection = (parent, { paging = {}, sorting = {} }) =>
  pagination(
    sorting ? sort(parent.items, sorting) : parent.items,
    paging
  )

module.exports = {
  sort,
  pagination,
  collection
}
