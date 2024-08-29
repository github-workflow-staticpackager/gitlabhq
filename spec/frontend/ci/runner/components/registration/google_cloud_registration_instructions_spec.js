import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createWrapper } from '@vue/test-utils';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import GoogleCloudRegistrationInstructions from '~/ci/runner/components/registration/google_cloud_registration_instructions.vue';
import runnerForRegistrationQuery from '~/ci/runner/graphql/register/runner_for_registration.query.graphql';
import provisionGoogleCloudRunnerQueryProject from '~/ci/runner/graphql/register/provision_google_cloud_runner_project.query.graphql';
import provisionGoogleCloudRunnerQueryGroup from '~/ci/runner/graphql/register/provision_google_cloud_runner_group.query.graphql';
import { STATUS_ONLINE } from '~/ci/runner/constants';
import {
  runnerForRegistration,
  mockAuthenticationToken,
  projectRunnerCloudProvisioningSteps,
  groupRunnerCloudProvisioningSteps,
} from '../../mock_data';

Vue.use(VueApollo);

const mockRunnerResponse = {
  data: {
    runner: {
      ...runnerForRegistration.data.runner,
      ephemeralAuthenticationToken: mockAuthenticationToken,
    },
  },
};
const mockRunnerWithoutTokenResponse = {
  data: {
    runner: {
      ...runnerForRegistration.data.runner,
      ephemeralAuthenticationToken: null,
    },
  },
};
const mockRunnerOnlineResponse = {
  data: {
    runner: {
      ...runnerForRegistration.data.runner,
      status: STATUS_ONLINE,
    },
  },
};

const mockProjectRunnerCloudSteps = {
  data: {
    project: {
      ...projectRunnerCloudProvisioningSteps,
    },
  },
};

const mockGroupRunnerCloudSteps = {
  data: {
    group: {
      ...groupRunnerCloudProvisioningSteps,
    },
  },
};

const mockRunnerId = `${getIdFromGraphQLId(runnerForRegistration.data.runner.id)}`;

describe('GoogleCloudRegistrationInstructions', () => {
  let wrapper;

  const findProjectIdInput = () => wrapper.findByTestId('project-id-input');
  const findRegionInput = () => wrapper.findByTestId('region-input');
  const findZoneInput = () => wrapper.findByTestId('zone-input');
  const findMachineTypeInput = () => wrapper.findByTestId('machine-type-input');

  const findProjectIdLink = () => wrapper.findByTestId('project-id-link');
  const findZoneLink = () => wrapper.findByTestId('zone-link');
  const findMachineTypeLink = () => wrapper.findByTestId('machine-types-link');
  const findToken = () => wrapper.findByTestId('runner-token');
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findInstructionsButton = () => wrapper.findByTestId('show-instructions-button');

  const getModal = () => extendedWrapper(createWrapper(document.querySelector('.gl-modal')));
  const findModalBashInstructions = () => getModal().findByTestId('bash-instructions');
  const findModalTerraformApplyInstructions = () =>
    getModal().findByTestId('terraform-apply-instructions');
  const findModalTerraformInstructions = () =>
    getModal().findByTestId('terraform-script-instructions');

  const fillInTextField = (formGroup, value) => {
    const input = formGroup.find('input');
    input.element.value = value;
    return input.trigger('change');
  };

  const fillInGoogleForm = () => {
    fillInTextField(findProjectIdInput(), 'dev-gcp-xxx-integrati-xxxxxxxx');
    fillInTextField(findRegionInput(), 'us-central1');
    fillInTextField(findZoneInput(), 'us-central1-a');
    fillInTextField(findMachineTypeInput(), 'n2d-standard-4');

    findInstructionsButton().vm.$emit('click');

    return waitForPromises();
  };

  const runnerWithTokenResolver = jest.fn().mockResolvedValue(mockRunnerResponse);
  const runnerWithoutTokenResolver = jest.fn().mockResolvedValue(mockRunnerWithoutTokenResponse);
  const runnerOnlineResolver = jest.fn().mockResolvedValue(mockRunnerOnlineResponse);
  const projectInstructionsResolver = jest.fn().mockResolvedValue(mockProjectRunnerCloudSteps);
  const groupInstructionsResolver = jest.fn().mockResolvedValue(mockGroupRunnerCloudSteps);

  const error = new Error('GraphQL error: One or more validations have failed');
  const errorResolver = jest.fn().mockRejectedValue(error);

  const defaultHandlers = [[runnerForRegistrationQuery, runnerWithTokenResolver]];
  const defaultProps = {
    runnerId: mockRunnerId,
    projectPath: 'test/project',
  };

  const createComponent = (handlers = defaultHandlers, props = defaultProps) => {
    wrapper = mountExtended(GoogleCloudRegistrationInstructions, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        ...props,
      },
      attachTo: document.body,
    });
  };

  it('displays form inputs', () => {
    createComponent();

    expect(findProjectIdInput().exists()).toBe(true);
    expect(findRegionInput().exists()).toBe(true);
    expect(findZoneInput().exists()).toBe(true);
    expect(findMachineTypeInput().exists()).toBe(true);
  });

  it('machine type input has a default value', () => {
    createComponent();

    expect(findMachineTypeInput().find('input').element.value).toEqual('n2d-standard-2');
  });

  it('contains external docs links', () => {
    createComponent();

    expect(findProjectIdLink().attributes('href')).toBe(
      'https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects',
    );
    expect(findZoneLink().attributes('href')).toBe(
      'https://console.cloud.google.com/compute/zones?pli=1',
    );
    expect(findMachineTypeLink().attributes('href')).toBe(
      'https://cloud.google.com/compute/docs/general-purpose-machines#n2d_machine_types',
    );
  });

  it('calls runner for registration query', () => {
    createComponent();

    expect(runnerWithTokenResolver).toHaveBeenCalled();
  });

  it('displays runner token', async () => {
    createComponent();

    await waitForPromises();

    expect(findToken().exists()).toBe(true);
    expect(findToken().text()).toBe(mockAuthenticationToken);
    expect(findClipboardButton().exists()).toBe(true);
    expect(findClipboardButton().props('text')).toBe(mockAuthenticationToken);
  });

  it('does not display runner token', async () => {
    createComponent([[runnerForRegistrationQuery, runnerWithoutTokenResolver]]);

    await waitForPromises();

    expect(findToken().exists()).toBe(false);
    expect(findClipboardButton().exists()).toBe(false);
  });

  it('Shows an alert when the form has empty fields', async () => {
    createComponent();

    findInstructionsButton().vm.$emit('click');

    await waitForPromises();

    expect(findAlert().exists()).toBe(true);

    expect(findAlert().text()).toContain(
      'To view the setup instructions, complete the previous form.',
    );
  });

  it('Hides an alert when the form is valid', async () => {
    createComponent([[provisionGoogleCloudRunnerQueryProject, projectInstructionsResolver]]);

    await fillInGoogleForm();

    expect(findAlert().exists()).toBe(false);
  });

  it('Shows a modal with the correspondent scripts for a project', async () => {
    createComponent([[provisionGoogleCloudRunnerQueryProject, projectInstructionsResolver]]);

    await fillInGoogleForm();

    expect(projectInstructionsResolver).toHaveBeenCalled();
    expect(groupInstructionsResolver).not.toHaveBeenCalled();

    expect(findModalBashInstructions().text()).not.toBeNull();
    expect(findModalTerraformInstructions().text()).not.toBeNull();
    expect(findModalTerraformApplyInstructions().text()).not.toBeNull();
  });

  it('Shows a modal with the correspondent scripts for a group', async () => {
    createComponent([[provisionGoogleCloudRunnerQueryGroup, groupInstructionsResolver]], {
      runnerId: mockRunnerId,
      groupPath: 'groups/test',
    });

    await fillInGoogleForm();

    expect(groupInstructionsResolver).toHaveBeenCalled();
    expect(projectInstructionsResolver).not.toHaveBeenCalled();

    expect(findModalBashInstructions().text()).not.toBeNull();
    expect(findModalTerraformInstructions().text()).not.toBeNull();
    expect(findModalTerraformApplyInstructions().text()).not.toBeNull();
  });

  it('Shows feedback when runner is online', async () => {
    createComponent([[runnerForRegistrationQuery, runnerOnlineResolver]]);

    await waitForPromises();

    expect(runnerOnlineResolver).toHaveBeenCalledTimes(1);
    expect(runnerOnlineResolver).toHaveBeenCalledWith({
      id: expect.stringContaining(mockRunnerId),
    });

    expect(wrapper.text()).toContain('Your runner is online');
  });

  describe('Field validation', () => {
    const expectValidation = (fieldGroup, { ariaInvalid, feedback }) => {
      expect(fieldGroup.attributes('aria-invalid')).toBe(ariaInvalid);
      expect(fieldGroup.find('input').attributes('aria-invalid')).toBe(ariaInvalid);
      expect(fieldGroup.text()).toContain(feedback);
    };

    beforeEach(() => {
      createComponent();
    });

    describe('cloud project id validates', () => {
      it.each`
        case                                 | input                                | ariaInvalid  | feedback
        ${'correct'}                         | ${'correct-project-name'}            | ${undefined} | ${''}
        ${'correct'}                         | ${'correct-project-name-1'}          | ${undefined} | ${''}
        ${'correct'}                         | ${'project'}                         | ${undefined} | ${''}
        ${'invalid (too short)'}             | ${'short'}                           | ${'true'}    | ${'Project ID must be'}
        ${'invalid (starts with a number)'}  | ${'1number'}                         | ${'true'}    | ${'Project ID must be'}
        ${'invalid (starts with uppercase)'} | ${'Project'}                         | ${'true'}    | ${'Project ID must be'}
        ${'invalid (contains uppercase)'}    | ${'pRoject'}                         | ${'true'}    | ${'Project ID must be'}
        ${'invalid (contains symbol)'}       | ${'pro!ect'}                         | ${'true'}    | ${'Project ID must be'}
        ${'invalid (too long)'}              | ${'a-project-name-that-is-too-long'} | ${'true'}    | ${'Project ID must be'}
        ${'invalid (ends with hyphen)'}      | ${'a-project-'}                      | ${'true'}    | ${'Project ID must be'}
        ${'invalid (missing)'}               | ${''}                                | ${'true'}    | ${'Project ID is required'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findProjectIdInput(), input);

        expectValidation(findProjectIdInput(), { ariaInvalid, feedback });
      });
    });

    describe('region validates', () => {
      it.each`
        case                           | input                | ariaInvalid  | feedback
        ${'correct'}                   | ${'us-central1'}     | ${undefined} | ${''}
        ${'correct'}                   | ${'europe-west8'}    | ${undefined} | ${''}
        ${'correct'}                   | ${'moon-up99'}       | ${undefined} | ${''}
        ${'invalid (is zone)'}         | ${'us-central1-a'}   | ${'true'}    | ${'Region must have'}
        ${'invalid (one part)'}        | ${'one2'}            | ${'true'}    | ${'Region must have'}
        ${'invalid (three parts)'}     | ${'one-two-three4'}  | ${'true'}    | ${'Region must have'}
        ${'invalid (contains symbol)'} | ${'one!-two-three4'} | ${'true'}    | ${'Region must have'}
        ${'invalid (typo)'}            | ${'one--two3'}       | ${'true'}    | ${'Region must have'}
        ${'invalid (too short)'}       | ${'wrong'}           | ${'true'}    | ${'Region must have'}
        ${'invalid (missing)'}         | ${''}                | ${'true'}    | ${'Region is required'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findRegionInput(), input);

        expectValidation(findRegionInput(), { ariaInvalid, feedback });
      });
    });

    describe('zone validates', () => {
      it.each`
        case                           | input                  | ariaInvalid  | feedback
        ${'correct'}                   | ${'us-central1-a'}     | ${undefined} | ${''}
        ${'correct'}                   | ${'europe-west8-b'}    | ${undefined} | ${''}
        ${'correct'}                   | ${'moon-up99-z'}       | ${undefined} | ${''}
        ${'invalid (one part)'}        | ${'one2-a'}            | ${'true'}    | ${'Zone must have'}
        ${'invalid (three parts)'}     | ${'one-two-three4-b'}  | ${'true'}    | ${'Zone must have'}
        ${'invalid (contains symbol)'} | ${'one!-two-three4-c'} | ${'true'}    | ${'Zone must have'}
        ${'invalid (typo)'}            | ${'one--two3-d'}       | ${'true'}    | ${'Zone must have'}
        ${'invalid (too short)'}       | ${'wrong'}             | ${'true'}    | ${'Zone must have'}
        ${'invalid (missing)'}         | ${''}                  | ${'true'}    | ${'Zone is required'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findZoneInput(), input);

        expectValidation(findZoneInput(), { ariaInvalid, feedback });
      });
    });

    describe('machine type validates', () => {
      it.each`
        case                            | input                   | ariaInvalid  | feedback
        ${'correct'}                    | ${'n2-standard-2'}      | ${undefined} | ${''}
        ${'correct'}                    | ${'t2d-standard-1'}     | ${undefined} | ${''}
        ${'correct'}                    | ${'t2a-standard-48'}    | ${undefined} | ${''}
        ${'correct'}                    | ${'t2d-standard-1'}     | ${undefined} | ${''}
        ${'correct'}                    | ${'c3-standard-4-lssd'} | ${undefined} | ${''}
        ${'correct'}                    | ${'f1-micro'}           | ${undefined} | ${''}
        ${'correct'}                    | ${'f1'}                 | ${undefined} | ${''}
        ${'invalid (uppercase letter)'} | ${'N2-standard-2'}      | ${'true'}    | ${'Machine type must have'}
        ${'invalid (number)'}           | ${'22-standard-2'}      | ${'true'}    | ${'Machine type must have'}
        ${'invalid (ends in dash)'}     | ${'22-standard-2-'}     | ${'true'}    | ${'Machine type must have'}
        ${'invalid (contains space)'}   | ${'n2-standard-2 '}     | ${'true'}    | ${'Machine type must have'}
        ${'invalid (missing)'}          | ${''}                   | ${'true'}    | ${'Machine type is required'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findMachineTypeInput(), input);

        expectValidation(findMachineTypeInput(), { ariaInvalid, feedback });
      });
    });

    it('Does not display a modal with text when validation errors occur', async () => {
      createComponent([[provisionGoogleCloudRunnerQueryProject, errorResolver]]);

      await fillInGoogleForm();

      expect(errorResolver).toHaveBeenCalled();

      expect(findAlert().text()).toContain(
        'To view the setup instructions, make sure all form fields are completed and correct.',
      );

      expect(findModalBashInstructions().text()).toBe('');
      expect(findModalTerraformInstructions().text()).toBe('');
      expect(findModalTerraformApplyInstructions().text()).toBe('');
    });
  });
});
