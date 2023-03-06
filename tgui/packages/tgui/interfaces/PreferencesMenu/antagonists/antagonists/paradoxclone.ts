import { Antagonist, Category } from '../base';
import { multiline } from 'common/string';

const ParadoxClone: Antagonist = {
  key: 'paradoxclone',
  name: 'Paradox Clone',
  description: [
    multiline`
    A freak time-space anomaly has teleported you into another reality!
    Now you have to find your counterpart and kill and replace them.
    `,
  ],
  category: Category.Midround,
};

export default ParadoxClone;
