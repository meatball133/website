import { useState, useCallback } from 'react'
import { QueryKey, useQueryCache } from 'react-query'

type ListItemType = {
  uuid: string
}

export const useItemList = <T extends ListItemType>(cacheKey: QueryKey) => {
  const queryCache = useQueryCache()
  const [editingItem, setEditingItem] = useState<T | null>(null)

  const handleEdit = useCallback((item) => {
    return () => setEditingItem(item)
  }, [])

  const handleEditCancel = useCallback(() => {
    setEditingItem(null)
  }, [])

  const handleDelete = useCallback(
    (deleted) => {
      queryCache.setQueryData<{ items: T[] }>([cacheKey], (oldData) => {
        if (!oldData) {
          return { items: [] }
        }

        return {
          items: oldData.items.filter((item) => item.uuid !== deleted.uuid),
        }
      })
    },
    [cacheKey, queryCache]
  )

  const handleUpdate = useCallback(
    (updated) => {
      queryCache.setQueryData<{ items: T[] }>([cacheKey], (oldData) => {
        if (!oldData) {
          return { items: [updated] }
        }

        return {
          items: oldData.items.map((item) => {
            return item.uuid === updated.uuid ? updated : item
          }),
        }
      })
    },
    [cacheKey, queryCache]
  )

  const getItemAction = useCallback(
    (item: T) => {
      return editingItem === item ? 'editing' : 'viewing'
    },
    [editingItem]
  )

  return {
    getItemAction,
    handleEdit,
    handleEditCancel,
    handleUpdate,
    handleDelete,
  }
}
