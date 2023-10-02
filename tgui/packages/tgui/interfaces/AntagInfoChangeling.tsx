import { BooleanLike } from 'common/react';
import { multiline } from 'common/string';
import { useBackend, useSharedState } from '../backend';
import { Button, Dimmer, Dropdown, Section, Stack, NoticeBox } from '../components';
import { Window } from '../layouts';
import { ObjectivePrintout, Objective, ReplaceObjectivesButton } from './common/Objectives';

const hivestyle = {
  fontWeight: 'bold',
  color: 'yellow',
};

const absorbstyle = {
  color: 'red',
  fontWeight: 'bold',
};

const revivestyle = {
  color: 'lightblue',
  fontWeight: 'bold',
};

const transformstyle = {
  color: 'orange',
  fontWeight: 'bold',
};

const storestyle = {
  color: 'lightgreen',
  fontWeight: 'bold',
};

const hivemindstyle = {
  color: 'violet',
  fontWeight: 'bold',
};

const fallenstyle = {
  color: 'black',
  fontWeight: 'bold',
};

type Memory = {
  name: string;
  story: string;
};

type Info = {
  true_name: string;
  hive_name: string;
  stolen_antag_info: string;
  memories: Memory[];
  objectives: Objective[];
  can_change_objective: BooleanLike;
};

// SKYRAT EDIT change height from 750 to 900
export const AntagInfoChangeling = (props, context) => {
  return (
    <Window width={720} height={900}>
      <Window.Content
        style={{
          'backgroundImage': 'none',
        }}>
        <Stack vertical fill>
          <Stack.Item maxHeight={16}>
            <IntroductionSection />
          </Stack.Item>
          {/* SKYRAT EDIT ADDITION START */}
          <Stack.Item>
            <Rules />
          </Stack.Item>
          {/* SKYRAT EDIT ADDITION END */}
          <Stack.Item grow={4}>
            <AbilitiesSection />
          </Stack.Item>
          <Stack.Item>
            <HivemindSection />
          </Stack.Item>
          <Stack.Item grow={3}>
            <Stack fill>
              <Stack.Item grow basis={0}>
                <MemoriesSection />
              </Stack.Item>
              <Stack.Item grow basis={0}>
                <VictimPatternsSection />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const HivemindSection = (props, context) => {
  const { act, data } = useBackend<Info>(context);
  const { true_name } = data;
  return (
    <Section fill title="Hivemind">
      <Stack vertical fill>
        <Stack.Item textColor="label">
          All Changelings, regardless of origin, are linked together by the{' '}
          <span style={hivemindstyle}>hivemind</span>. You may communicate to
          other Changelings under your mental alias,{' '}
          <span style={hivemindstyle}>{true_name}</span>, by starting a message
          with <span style={hivemindstyle}>:g</span>. Work together, and you
          will bring the station to new heights of terror.
        </Stack.Item>
        <Stack.Item>
          <NoticeBox danger>
            Other Changelings are strong allies, but some Changelings may betray
            you. Changelings grow in power greatly by absorbing their kind, and
            getting absorbed by another Changeling will leave you as a{' '}
            <span style={fallenstyle}>Fallen Changeling</span>. There is no
            greater humiliation.
          </NoticeBox>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const IntroductionSection = (props, context) => {
  const { act, data } = useBackend<Info>(context);
  const { true_name, hive_name, objectives, can_change_objective } = data;
  return (
    <Section
      fill
      title="Intro"
      scrollable={!!objectives && objectives.length > 4}>
      <Stack vertical fill>
        <Stack.Item fontSize="25px">
          You are {true_name} from the
          <span style={hivestyle}> {hive_name}</span>.
        </Stack.Item>
        <Stack.Item>
          <ObjectivePrintout
            objectives={objectives}
            objectiveFollowup={
              <ReplaceObjectivesButton
                can_change_objective={can_change_objective}
                button_title={'Evolve New Directives'}
                button_colour={'green'}
              />
            }
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const AbilitiesSection = (props, context) => {
  const { data } = useBackend<Info>(context);
  return (
    <Section fill title="Abilities">
      <Stack fill>
        <Stack.Item basis={0} grow>
          <Stack fill vertical>
            <Stack.Item basis={0} textColor="label" grow>
              Your
              <span style={absorbstyle}>&ensp;Absorb DNA</span> ability allows
              you to steal the DNA and memories of a victim. The
              <span style={absorbstyle}>&ensp;Extract DNA Sting</span> ability
              also steals the DNA of a victim, and is undetectable, but does not
              grant you their memories or speech patterns.
            </Stack.Item>
            <Stack.Divider />
            <Stack.Item basis={0} textColor="label" grow>
              Your
              <span style={revivestyle}>&ensp;Reviving Stasis</span> ability
              allows you to revive. It means nothing short of a complete body
              destruction can stop you! Obviously, this is loud and so should
              not be done in front of people you are not planning on silencing.
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Divider />
        <Stack.Item basis={0} grow>
          <Stack fill vertical>
            <Stack.Item basis={0} textColor="label" grow>
              Your
              <span style={transformstyle}>&ensp;Transform</span> ability allows
              you to change into the form of those you have collected DNA from,
              lethally and nonlethally. It will also mimic (NOT REAL CLOTHING)
              the clothing they were wearing for every slot you have open.
            </Stack.Item>
            <Stack.Divider />
            <Stack.Item basis={0} textColor="label" grow>
              The
              <span style={storestyle}>&ensp;Cellular Emporium</span> is where
              you purchase more abilities beyond your starting kit. You have 10
              genetic points to spend on abilities and you are able to readapt
              after absorbing a body, refunding your points for different kits.
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const MemoriesSection = (props, context) => {
  const { data } = useBackend<Info>(context);
  const { memories } = data;
  const [selectedMemory, setSelectedMemory] = useSharedState(
    context,
    'memory',
    (!!memories && memories[0]) || null
  );
  const memoryMap = {};
  for (const index in memories) {
    const memory = memories[index];
    memoryMap[memory.name] = memory;
  }
  return (
    <Section
      fill
      scrollable={!!memories && !!memories.length}
      title="Stolen Memories"
      buttons={
        <Button
          icon="info"
          tooltipPosition="left"
          tooltip={multiline`
            Absorbing targets allows
            you to collect their memories. They should
            help you impersonate your target!
          `}
        />
      }>
      {(!!memories && !memories.length && (
        <Dimmer fontSize="20px">Absorb a victim first!</Dimmer>
      )) || (
        <Stack vertical>
          <Stack.Item>
            <Dropdown
              width="100%"
              selected={selectedMemory?.name}
              options={memories.map((memory) => {
                return memory.name;
              })}
              onSelected={(selected) => setSelectedMemory(memoryMap[selected])}
            />
          </Stack.Item>
          <Stack.Item>{!!selectedMemory && selectedMemory.story}</Stack.Item>
        </Stack>
      )}
    </Section>
  );
};

const VictimPatternsSection = (props, context) => {
  const { data } = useBackend<Info>(context);
  const { stolen_antag_info } = data;
  return (
    <Section
      fill
      scrollable={!!stolen_antag_info}
      title="Additional Stolen Information">
      {(!!stolen_antag_info && stolen_antag_info) || (
        <Dimmer fontSize="20px">Absorb a victim first!</Dimmer>
      )}
    </Section>
  );
};

// SKYRAT EDIT ADDITION START
const Rules = (props, context) => {
  return (
    <Stack vertical>
      <Stack.Item bold>Special Rules:</Stack.Item>
      <Stack.Item>
        {
          '- If people can prove you’re a changeling, you are immediately sentenced to being placed in Perma, or the most convenient containment. Afterwards, if you prove uncontainable, or particularly violent, you’re valid for round removal.'
        }
      </Stack.Item>
      <Stack.Item>
        {
          '- Undeniable Proof of Changeling includes: Arm Blade, Tentacle Arm, Chitinous Armor, Ling Space Suit, Ling Shield, Horror Form, Digital Camo, Cryo Sting, Self-Revival, Regeneration, Unexplainable Fast Healing.'
        }
      </Stack.Item>
      <Stack.Item>
        {'- Horror Forms are in a Permanently Mechanical state.'}
      </Stack.Item>
      <Stack.Item bold>Metaprotections:</Stack.Item>
      <Stack.Item>
        {
          'Everyone knows that changelings are real. Some people can deny this if they want. Crew that can produce arm blades, or organic armor or weapons, or shapeshift into other people, should be reported to security with all haste. Security, Science, and Medical are all aware that Changelings can be suppressed with BZ gas. Everyone is aware of the abilities listed prior as Undeniable Proof of Changelings. Anything not listed is unknown to the entire crew.'
        }
      </Stack.Item>
    </Stack>
  );
};
// SKYRAT EDIT ADDITION END
