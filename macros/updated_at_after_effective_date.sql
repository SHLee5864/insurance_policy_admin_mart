{% test updated_at_after_effective_date(model) %}

select *
from {{ model }}
where updated_at < effective_date

{% endtest %}
