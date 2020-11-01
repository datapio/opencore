const sort = (items, sorting) => {
  if (sorting) {
    const sorted = items.slice().sort((item, other) =>
      item[sorting.key] - other[sorting.key]
    )

    if (sorting.reversed) {
      sorted.reversed()
    }

    return sorted
  }

  return items
}

const pagination = (items, paging) => {
  if (paging) {
    const offset = paging.offset || 0
    const defaultLimit = items.length - offset
    const limit = paging.limit || defaultLimit

    return items.slice(offset).slice(0, limit)
  }

  return items
}

const collection = (parent, { paging, sorting }) =>
  pagination(sort(parent.items, sorting), paging)
