const sort = (items, sorting) => {
  if (sorting) {
    const sorted = items.slice().sort((a, b) =>
      b[sorting.key] - a[sorting.key]
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
    const limit = paging.limit || (items.length - offset)

    return items.slice(offset).slice(0, limit)
  }

  return items
}

const collection = (parent, { paging, sorting }) =>
  pagination(sort(parent.items, sorting), paging)
