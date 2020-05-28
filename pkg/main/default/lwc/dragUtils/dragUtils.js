import { isEmpty } from 'c/utils';

/** The following properties need to be set for each drag item:
 * - id ('data-id' property)
 * - index ('data-index' property)
 *
 * @param obj - represents the component's instance (this)
 *
 * */

const cancel = (evt) => {
    if (evt.stopPropagation) evt.stopPropagation();
    if (evt.preventDefault) evt.preventDefault();
    return false;
};

const handleDragEnter = (obj, evt) => {
    cancel(evt);
    if (isEmpty(obj.fromIndex)) {
      obj.fromIndex = evt.currentTarget.dataset.index;
    }
};

const handleDragOver = (obj, evt) => {
    cancel(evt);
    addDragOverStyle(obj, evt.currentTarget.dataset.index);
};

const handleDragLeave = (obj, evt) => {
    cancel(evt);
    removeDragOverStyle(obj, evt.currentTarget.dataset.index);
};

const addDragOverStyle = (obj, index) => {
    const draggableElement = obj.template.querySelector('[data-index="'+ index + '"]');
    draggableElement.classList.add('over');
};

const removeDragOverStyle = (obj, index) => {
    const draggableElement = obj.template.querySelector('[data-index="' + index + '"]');
    draggableElement.classList.remove('over');
};

const handleDrop = (obj, evt, handleUpdateList) => {
    cancel(evt);
    const toIndex = evt.currentTarget.dataset.index;
    const updatedList = getReorderedList(obj.list, obj.fromIndex, toIndex);
    obj.fromIndex = null;
    handleUpdateList(updatedList);
    removeDragOverStyle(obj, toIndex);
};

const getReorderedList = (list, fromIndex, toIndex) => {
    const listCopy = list.slice();

    if (fromIndex !== toIndex) {
      const itemToMove = listCopy[fromIndex];
      listCopy.splice(fromIndex, 1);
      listCopy.splice(toIndex, 0, itemToMove);
    }

    return listCopy;
};

const itemDragStart = (obj, id) => {
    let draggableElement = obj.template.querySelector('[data-id="' + id + '"]');
    if (!isEmpty(draggableElement)) {
        draggableElement.classList.add('drag');
    }
};

const itemDragEnd = (obj, id) => {
    //Reset the style
    let draggableElement = obj.template.querySelector('[data-id="' + id + '"]');
    if (!isEmpty(draggableElement)) {
        draggableElement.classList.remove('drag');
    }
};

export {
    handleDragEnter,
    handleDragOver,
    handleDragLeave,
    addDragOverStyle,
    removeDragOverStyle,
    handleDrop,
    itemDragStart,
    itemDragEnd
};