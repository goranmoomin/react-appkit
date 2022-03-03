import React, { useState } from 'react';
import { render, useConstraint } from '../lib/appkit-reconciler';

function createRandomString() {
  return [...Array(16)].map(() => Math.random().toString(36)[2]).join('');
}

function SimpleView() {
  let [labelStrings, setLabelStrings] = useState([]);
  let constraint1Leading = useConstraint(8);
  let constraint1Trailing = useConstraint(8);
  let constraint1Top = useConstraint(8);
  let constraint2Leading = useConstraint(8);
  let constraint2Trailing = useConstraint(8);
  let constraint2Top = useConstraint(8);
  let constraint2Bottom = useConstraint(8);
  let constraintWidth = useConstraint();

  function addLabelString() {
    setLabelStrings(labelStrings => [...labelStrings, createRandomString()]);
  }

  return (
    <stack orientation='vertical'>
      <button title='Create random labels' action={addLabelString} />
      <view
        leading={[constraint1Leading.to, constraint2Leading.to]}
        trailing={[constraint1Trailing.from, constraint2Trailing.from]}
        top={[constraint1Top.to]}
        bottom={[constraint2Bottom.from]}
        color={{ r: 0.5, g: 0.6, b: 0.7, a: 1.0 }}>
        <button
          leading={[constraint1Leading.from]}
          trailing={[constraint1Trailing.to]}
          top={[constraint1Top.from]}
          bottom={[constraint2Top.to]}
          width={[constraintWidth.from]}
          title='Hello 1'
          action={() => { }} />
        <button
          leading={[constraint2Leading.from]}
          trailing={[constraint2Trailing.to]}
          top={[constraint2Top.from]}
          bottom={[constraint2Bottom.to]}
          width={[constraintWidth.to]}
          title='Hello 2'
          action={() => { }} />
      </view>
      {labelStrings.map(labelString => <label string={labelString} />)}
    </stack>
  );
}

render(<SimpleView />);
