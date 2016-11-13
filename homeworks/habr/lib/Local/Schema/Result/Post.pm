use utf8;
package Local::Schema::Result::Post;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Local::Schema::Result::Post

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<post>

=cut

__PACKAGE__->table("post");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 topic

  data_type: 'text'
  is_nullable: 0

=head2 rating

  data_type: 'double precision'
  is_nullable: 0

=head2 views

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 stars

  data_type: 'integer'
  is_nullable: 0

=head2 author

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "topic",
  { data_type => "text", is_nullable => 0 },
  "rating",
  { data_type => "double precision", is_nullable => 0 },
  "views",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "stars",
  { data_type => "integer", is_nullable => 0 },
  "author",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<Local::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "author",
  "Local::Schema::Result::User",
  { username => "author" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 comments

Type: has_many

Related object: L<Local::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "Local::Schema::Result::Comment",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 commentors

Type: many_to_many

Composing rels: L</comments> -> commentor

=cut

__PACKAGE__->many_to_many("commentors", "comments", "commentor");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2016-11-13 18:17:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5A4pd72dbo7DFGvZ5N9SHg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
