package Opencop;
use Mojo::Base 'Mojolicious';

use Mojo::Pg;
use Opencop::Model::Audit;
use Opencop::Model::Account;
use Opencop::Model::Auth;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  $self->plugin('Config');
  
  $self->helper(pg => sub { state $pg = Mojo::Pg->new( shift->config('pg'))});
  $self->helper(audit => sub { 
  	my $app = shift;
	state $core = Opencop::Model::Audit->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 :  0)
  });
  $self->helper(account => sub {
  	my $app = shift;
  	state $account = Opencop::Model::Account->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 : 0);
  });
  $self->helper(auth => sub {
  	my $app = shift;
  	state $auth = Opencop::Model::Auth->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 : 0);
  });
  
  $self->helper(meta_keywords => sub {
  	
  });
  
  $self->helper(meta_description => sub{
  	
  });
  
  $self->hook(before_dispatch => sub{
	my $self = shift;
	$self->audit->page_visit($self->tx);
  });
  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('core#index')->name('index');
  $r->get('/customer')->to('customer#index')->name('customer_index');
  my $authed = $r->under()->to('auth#check_session');
  $authed->get('/ticket/new')->to('ticket#new_form')->name('new_ticket_form');
  $authed->post('/ticket/new')->to('ticket#new')->name('new_ticket');
  $authed->post('/ticket/update/:ticket_number')->to('ticket#update')->name('update_ticket');
  $authed->get('/ticket/queue/all')->to('ticket#all_queues')->name('view_all_ticket_queues');
  $authed->get('/ticket/queue/:queue')->to('ticket#queue')->name('view_ticket_queue');
  $authed->get('/ticket/:ticket_number')->to('ticket#view_ticket')->name('view_ticket');
  $authed->get('/work-order/new')->to('workorder#new_form')->name('new_work_order_form');
  $authed->post('/work-order')->to('workorder#new')->name('new_work_order');
  $authed->get('/work-order/queue/all')->to('workorder#all_work_orders')->name('view_all_work_orders');
  $authed->get('/work-order/queue/:work_order_queue')->to('workorder#queue')->name('view_work_order_queue');
  $authed->post('/work-order/update/:work_order_number')->to('workorder#update')->name('update_work_order');
  $authed->get('/work-order/:work_order_number')->to('workorder#view_work_order')->name('view_work_order');
  $authed->get('/report-builder')->to('reports#report_builder_form')->name('report_builder_form');
  $authed->post('/report-builder')->to('reports#save_report')->name('save_report');
  $authed->get('/reports')->to('reports#view_all')->name('view_all_reports');
  $authed->get('/report/:report')->to('report#view')->name('view_report');
  $authed->get('/inventory/add')->to('inventory#add_form')->name('add_inventory_form');
  $authed->post('/inventory/add')->to('inventory#add')->name('add_inventory');
  $authed->get('/inventory')->to('inventory#view_all')->name('view_all_inventory');
  $authed->get('/inventory/configure')->to('inventory#configure_form')->name('configure_inventory_form');
  $authed->post('/inventory/configure')->to('inventory#configure')->name('configure_inventory');
  $authed->get('/inventory/company/:company')->to('inventory#view_company')->name('view_company_inventory');
  $authed->get('/inventory/:asset_id')->to('inventory#view')->name('view_asset');
  $authed->get('/customer/view/all')->to('customer#view_all')->name('view_all_customers');
  $authed->post('/customer/edit')->to('customer#edit')->name('edit_customer');
  $authed->get('/customer/:customer')->to('customer#view')->name('view_customer');
  $authed->get('/admin/work_orders')->to('admin#work_orders')->name('admin_work_orders');
  $authed->get('/admin/users')->to('admin#view_users')->name('view_users');
  $authed->get('/admin/new/user')->to('admin#new_user_form')->name('new_user_form');
  $authed->post('/admin/new/user')->to('admin#new_user')->name('new_user');
  $authed->post('/admin/edit/user')->to('admin#edit_user')->name('edit_user');
  $authed->get('/admin/settings/global')->to('admin#global_settings')->name('global_settings');
  $authed->post('/admin/settings/global')->to('admin#save_global_settings')->name('save_global_settings');
  $authed->get('/admin/groups')->to('admin#view_groups')->name('view_groups');
  $authed->get('/admin/new/group')->to('admin#new_group_form')->name('new_group_form');
  $authed->post('/admin/new/group')->to('admin#new_group')->name('new_group');
  $authed->post('/admin/edit/group')->to('admin#edit_group')->name('edit_group');
  $authed->get('/permissions')->to('admin#view_permissions')->name('view_permissions');
  $authed->get('/permissions/new')->to('admin#new_permission_form')->name('new_permission_form');
  $authed->post('/permissions/new')->to('admin#new_permission')->name('new_permission');
  $authed->post('/permissions/edit')->to('admin#edit_permission')->name('edit_permission');
  $authed->post('/logout')->to('auth#logout')->name('logout');
}

1;
