import { useRef } from 'react';
import Reconciler from 'react-reconciler';

function createReplacer() {
  let seen = new WeakSet();
  return (key, value) => {
    if (key.startsWith('_')) { return; }
    if (typeof value === 'object' && value !== null) {
      if (seen.has(value)) { return; }
      seen.add(value);
    }
    return value;
  };
};

function fmt(strings, ...expressions) {
  let string = strings[0];
  for (let i = 0; i < expressions.length; i++) {
    if (typeof expressions[i] === 'object') {
      string += JSON.stringify(expressions[i], createReplacer());
    } else {
      string += expressions[i].toString();
    }
    string += strings[i + 1];
  }

  return string;
}

let reconciler = Reconciler({
  supportsMutation: true,
  supportsPersistence: false,
  createInstance(type, props, rootContainer, hostContext, _internalHandle) {
    nslog(fmt`createInstance(${type}, ${props}, ${rootContainer}, ${hostContext}, internalHandle)`);
    return createView(type, props);
  },
  createTextInstance(text, rootContainer, hostContext, _internalHandle) {
    nslog(fmt`createTextInstance(${text}, ${rootContainer}, ${hostContext}, internalHandle)`);
    return text;
  },
  appendInitialChild(parentInstance, child) {
    nslog(fmt`appendInitialChild(${parentInstance}, ${child})`);
    addView(parentInstance, child);
  },
  finalizeInitialChildren(_instance, _type, _props, _rootContainer, _hostContext) { return false; },
  prepareUpdate(_instance, _type, _oldProps, _newProps, _rootContainer, _hostContext) { return true; },
  shouldSetTextContent(_type, _props) { return false; },
  getRootHostContext(_rootContainer) { return null; },
  getChildHostContext(_parentHostContext, _type, _rootContainer) { return null; },
  getPublicInstance(instance) { return instance; },
  prepareForCommit(_containerInfo) { return null; },
  resetAfterCommit(_containerInfo) { },
  preparePortalMount(_containerInfo) { },
  now() { return performance.now(); },
  scheduleTimeout(fn, delay) { return setTimeout(fn, delay); },
  cancelTimeout(id) { clearTimeout(id); },
  noTimeout: -1,
  isPrimaryRenderer: false,

  appendChild(parentInstance, child) {
    nslog(fmt`appendChild(${parentInstance}, ${child})`);
    addView(parentInstance, child);
  },
  appendChildToContainer(container, child) {
    nslog(fmt`appendChildToContainer(${container}, ${child})`);
    addViewToRoot(child);
  },
  insertBefore: undefined,
  insertInContainerBefore: undefined,
  removeChild(parentInstance, child) {
    nslog(fmt`removeChild(${parentInstance}, ${child})`);
    removeFromSuperview(child);
  },
  removeChildFromContainer(container, child) {
    nslog(fmt`removeChildFromContainer(${container}, ${child})`);
    removeFromSuperview(child);
  },
  resetTextContent: undefined,
  commitTextUpdate: undefined,
  commitMount: undefined,
  commitUpdate(instance, updatePayload, type, prevProps, nextProps, _internalHandle) {
    nslog(fmt`commitUpdate(${instance}, ${updatePayload}, ${type}, ${prevProps}, ${nextProps}, internalHandle)`);
    updateView(instance, type, prevProps, nextProps);
  },
  hideInstance: undefined,
  hideTextInstance: undefined,
  unhideInstance: undefined,
  unhideTextInstance: undefined,
  clearContainer(container) {
    nslog(fmt`clearContainer(${container})`);
  },
});

export function render(view) {
  let root = reconciler.createContainer(null, 0, false, null);
  reconciler.updateContainer(view, root, null);
}

// useConstraint(constant = 0, relation = NSLayoutRelationEqual, multiplier = 1)
export function useConstraint(constant = 0, multiplier = 1) {
  return useRef(createEqualConstraint(constant, multiplier)).current;
}
