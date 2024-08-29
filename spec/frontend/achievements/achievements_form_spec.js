import { GlAlert, GlButton, GlFormFields } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createAchievementResponse from 'test_fixtures/graphql/create_achievement_response.json';
import createAchievementErrorResponse from 'test_fixtures/graphql/create_achievement_error_response.json';
import getGroupAchievementsResponse from 'test_fixtures/graphql/get_group_achievements_response.json';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AchievementsForm from '~/achievements/components/achievements_form.vue';
import createAchievementMutation from '~/achievements/components/graphql/create_achievement.mutation.graphql';
import getGroupAchievementsQuery from '~/achievements/components/graphql/get_group_achievements.query.graphql';
import routes from '~/achievements/routes';

jest.mock('~/lib/logger');

describe('Achievements form', () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const groupFullPath = 'flightjs';
  const mockToastShow = jest.fn();

  let wrapper;

  const findError = () => wrapper.findComponent(GlAlert);
  const findFormFields = () => wrapper.findComponent(GlFormFields);
  const findSaveButton = () => wrapper.findComponent(GlButton);

  const successMutationHandler = jest.fn().mockResolvedValue(createAchievementResponse);

  const mountComponent = ({ mutationHandler = successMutationHandler } = {}) => {
    const fakeApollo = createMockApollo([[createAchievementMutation, mutationHandler]]);
    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getGroupAchievementsQuery,
      variables: { groupFullPath },
      data: getGroupAchievementsResponse.data,
    });

    const router = new VueRouter({
      base: '',
      mode: 'history',
      routes,
    });
    router.push('/new');

    wrapper = shallowMountExtended(AchievementsForm, {
      apolloProvider: fakeApollo,
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
      propsData: { storeQuery: { query: getGroupAchievementsQuery, variables: { groupFullPath } } },
      provide: {
        groupFullPath,
        groupId: 7,
      },
      router,
    });
  };

  it('renders form fields with fields prop containing name and description objects', () => {
    mountComponent();

    expect(findFormFields().props('fields')).toEqual(
      expect.objectContaining({
        name: expect.any(Object),
        description: expect.any(Object),
      }),
    );
  });

  it('renders save button', () => {
    mountComponent();

    expect(findSaveButton().exists()).toBe(true);
  });

  describe('when mutation is successful', () => {
    it('displays the correct toast message', async () => {
      mountComponent();

      findFormFields().vm.$emit('input', { name: 'Achievement' });
      findFormFields().vm.$emit('submit');
      await waitForPromises();

      expect(mockToastShow).toHaveBeenCalledWith('Achievement has been added.');
    });
  });

  describe('when mutation returns an error', () => {
    it('displays the error message', async () => {
      mountComponent({
        mutationHandler: jest.fn().mockResolvedValue(createAchievementErrorResponse),
      });

      findFormFields().vm.$emit('input', { name: 'Achievement' });
      findFormFields().vm.$emit('submit');
      await waitForPromises();

      expect(mockToastShow).not.toHaveBeenCalled();
      expect(findError().text()).toBe('Name has already been taken');
    });
  });

  describe('when mutation fails', () => {
    it('displays the correct toast message', async () => {
      mountComponent({ mutationHandler: jest.fn().mockRejectedValue('ERROR') });

      findFormFields().vm.$emit('input', { name: 'Achievement' });
      findFormFields().vm.$emit('submit');
      await waitForPromises();

      expect(findError().text()).toBe('Something went wrong. Please try again.');
    });
  });
});
