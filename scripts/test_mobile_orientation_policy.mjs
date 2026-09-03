import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const source = fs.readFileSync(new URL('../game/features/mobile_controls/mobile_orientation_policy.gd', import.meta.url), 'utf8');
const request = source.match(/const WEB_REQUEST := """([\s\S]*?)"""/)[1];
const release = source.match(/const WEB_RELEASE := """([\s\S]*?)"""/)[1];
const rejection = () => Promise.reject(new Error('browser restriction'));
async function run({ lock, fullscreen, alreadyFull = false, requestFull = false } = {}) {
  const calls = [];
  const orientation = lock === null ? {} : {
    lock: mode => { calls.push(mode); return lock?.(); },
    unlock: () => calls.push('unlock'),
  };
  const document = { fullscreenElement: alreadyFull, documentElement: {} };
  if (fullscreen !== null) document.documentElement.requestFullscreen = () => {
    calls.push('fullscreen'); return fullscreen?.();
  };
  const context = vm.createContext({ window: { screen: { orientation } }, document });
  vm.runInContext(request.replaceAll('FULLSCREEN_REQUEST', String(requestFull)), context);
  await new Promise(setImmediate);
  return { calls, context };
}

assert.deepEqual((await run()).calls, ['landscape']);
assert.deepEqual((await run({ requestFull: true })).calls, ['fullscreen', 'landscape']);
assert.deepEqual((await run({ requestFull: true, alreadyFull: true })).calls, ['landscape']);
assert.deepEqual((await run({ requestFull: true, fullscreen: rejection, lock: rejection })).calls, ['fullscreen', 'landscape']);
assert.deepEqual((await run({ requestFull: true, fullscreen: null, lock: null })).calls, []);
assert.deepEqual((await run({ lock: () => { throw new Error('unsupported'); } })).calls, ['landscape']);
const pc = await run();
vm.runInContext(release, pc.context);
assert.deepEqual(pc.calls, ['landscape', 'unlock']);
vm.runInContext(release, vm.createContext({ window: {} }));
console.log('MOBILE_ORIENTATION_WEB_OK landscape default no_auto_fullscreen supported denied unavailable sync_throw release');
