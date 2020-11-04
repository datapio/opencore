const { describe, it } = require('mocha')
const { expect } = require('chai')

describe('graphql/utils', () => {
  describe('collection', () => {
    const collection = require('../../../src/graphql/utils/collection')

    describe('sort', () => {
      const items = [
        {i: 4},
        {i: 2},
        {i: 3}
      ]

      it('should return a list sorted by a key', () => {
        const result = collection.sort(items, { key: 'i' })
        expect(result).to.deep.equal([
          {i: 2},
          {i: 3},
          {i: 4}
        ])
      })

      it('should return a list sorted in reverse', () => {
        const result = collection.sort(items, { key: 'i', reversed: true })
        expect(result).to.deep.equal([
          {i: 4},
          {i: 3},
          {i: 2}
        ])
      })
    })

    describe('pagination', () => {
      const items = [1, 2, 3, 4, 5]

      it('should return the original list when no pagination is specified', () => {
        const result = collection.pagination(items, {})
        expect(result).to.deep.equal([1, 2, 3, 4, 5])
      })

      it('should return an offsetted list', () => {
        const result = collection.pagination(items, { offset: 1 })
        expect(result).to.deep.equal([2, 3, 4, 5])
      })

      it('should return a limitted list', () => {
        const result = collection.pagination(items, { limit: 2 })
        expect(result).to.deep.equal([1, 2])
      })

      it('should return an offsetted and limitted list', () => {
        const result = collection.pagination(items, { offset: 1, limit: 2 })
        expect(result).to.deep.equal([2, 3])
      })

      it('should return an empty list if the offset is bigger than the length', () => {
        const result = collection.pagination(items, { offset: 10 })
        expect(result).to.deep.equal([])
      })

      it('should return return an offsetted list from the end if the offset is negative', () => {
        const result = collection.pagination(items, { offset: -3 })
        expect(result).to.deep.equal([3, 4, 5])
      })

      it('should return the original list if the limit is bigger than the length', () => {
        let result = collection.pagination(items, { limit: 10 })
        expect(result).to.deep.equal([1, 2, 3, 4, 5])

        result = collection.pagination(items, { offset: 1, limit: 10 })
        expect(result).to.deep.equal([2, 3, 4, 5])
      })
    })

    describe('collection', () => {
      it('should return the items paginated', () => {
        const result = collection.collection(
          { items: [
            {i: 10},
            {i: 23},
            {i: 3},
            {i: 14},
            {i: 5}
          ]},
          {
            paging: {
              offset: 1,
              limit: 2
            }
          }
        )
        expect(result).to.deep.equal([
          {i: 23},
          {i: 3}
        ])
      })

      it('should return the items sorted and paginated', () => {
        const result = collection.collection(
          { items: [
            {i: 10},
            {i: 23},
            {i: 3},
            {i: 14},
            {i: 5}
          ]},
          {
            paging: {
              offset: 1,
              limit: 2
            },
            sorting: {
              key: 'i'
            }
          }
        )

        expect(result).to.deep.equal([
          {i: 5},
          {i: 10}
        ])
      })
    })
  })
})