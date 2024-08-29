import projects from 'test_fixtures/api/users/projects/get.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ProjectsListItem from '~/vue_shared/components/projects_list/projects_list_item.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

describe('ProjectsList', () => {
  let wrapper;

  const defaultPropsData = {
    projects: convertObjectPropsToCamelCase(projects, { deep: true }),
    listItemClass: 'gl-px-5',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(ProjectsList, {
      propsData: defaultPropsData,
    });
  };

  it('renders list with `ProjectListItem` component', () => {
    createComponent();

    const projectsListItemWrappers = wrapper.findAllComponents(ProjectsListItem).wrappers;
    const expectedProps = projectsListItemWrappers.map((projectsListItemWrapper) =>
      projectsListItemWrapper.props(),
    );
    const expectedClasses = projectsListItemWrappers.map((projectsListItemWrapper) =>
      projectsListItemWrapper.classes(),
    );

    expect(expectedProps).toEqual(
      defaultPropsData.projects.map((project) => ({
        project,
        showProjectIcon: false,
      })),
    );
    expect(expectedClasses).toEqual(
      defaultPropsData.projects.map(() => [defaultPropsData.listItemClass]),
    );
  });

  describe('when `ProjectListItem` emits `delete` event', () => {
    const [firstProject] = defaultPropsData.projects;

    beforeEach(() => {
      createComponent();

      wrapper.findComponent(ProjectsListItem).vm.$emit('delete', firstProject);
    });

    it('emits `delete` event', () => {
      expect(wrapper.emitted('delete')).toEqual([[firstProject]]);
    });
  });
});
