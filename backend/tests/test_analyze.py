import asyncio
import base64
import io
import json
import hashlib
from pathlib import Path

import httpx
import pytest
from fastapi.testclient import TestClient
from PIL import Image

from backend import app as api


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'test-only-key')
    with TestClient(api.app) as client:
        yield client


def image_bytes():
    output = io.BytesIO()
    Image.new('RGB', (20, 20), 'green').save(output, format='PNG')
    return output.getvalue()


def material(**changes):
    return dict(name='Plastik su şişesi', material_id='pet_bottle', quantity=2,
                confidence='uncertain', requires_confirmation=True) | changes


def post(client, data=None):
    return client.post('/analyze', files={'file': ('image.png', image_bytes() if data is None else data, 'image/png')})


def mock_result(monkeypatch, materials):
    async def fake(image, api_key):
        assert image.startswith(b'\xff\xd8')
        assert api_key == 'test-only-key'
        return json.dumps({'materials': materials})
    monkeypatch.setattr(api, 'call_gemini', fake)


def test_analyze_and_unknown_preservation(client, monkeypatch):
    mock_result(monkeypatch, [material(), material(name='Tahta parçası', material_id='wood', confidence='certain', requires_confirmation=False)])
    response = post(client)
    assert response.status_code == 200
    items = response.json()['materials']
    assert items[0] == material()
    assert items[1]['name'] == 'Tahta parçası'
    assert items[1]['material_id'] is None
    assert items[1]['confidence'] == 'uncertain'
    assert items[1]['requires_confirmation'] is True


@pytest.mark.parametrize('material_id', sorted(api.MATERIAL_IDS))
def test_all_ids(client, monkeypatch, material_id):
    mock_result(monkeypatch, [material(name='Kâğıt bardak' if material_id == 'paper_cup' else 'Plastik su şişesi', material_id=material_id.upper())])
    assert post(client).json()['materials'][0]['material_id'] == material_id


@pytest.mark.parametrize('case', json.loads((Path(__file__).resolve().parents[2] / 'test/fixtures/material_label_cases.json').read_text(encoding='utf-8')))
def test_shared_material_labels(case):
    from backend.material_normalization import is_electronic, is_paper_cup
    assert is_paper_cup(case['name']) == case['paper']
    assert is_electronic(case['name']) == case['electronic']


def test_headphones_and_paper_cup_preserve_detections(client, monkeypatch):
    mock_result(monkeypatch, [material(name='Kulaklık', material_id='plastic_packaging'), material(name='Karton kahve bardağı', material_id='cardboard_roll')])
    result = post(client).json()['materials']
    assert len(result) == 2
    assert result[0]['name'] == 'Kulaklık'
    assert result[0]['material_id'] is None
    assert result[1]['material_id'] == 'paper_cup'
    assert result[1]['requires_confirmation'] is True


@pytest.mark.parametrize('name', ['Plastik bardak', 'Cam bardağı'])
def test_nonpaper_cup_cannot_be_a_roll_or_paper(name):
    for material_id in ['paper_cup', 'clean_paper', 'cardboard_roll']:
        result = api.normalize_analysis(json.dumps({'materials': [material(name=name, material_id=material_id)]})).materials[0]
        assert result.material_id is None
        assert result.requires_confirmation is True


def test_retained_recipe_records_unchanged():
    root = Path(__file__).resolve().parents[2]
    expected = json.loads((root / 'test/fixtures/retained_recipe_hashes.json').read_text())
    catalog = json.loads((root / 'assets/recipes/projects.json').read_text(encoding='utf-8'))
    records = {p['id']: p for p in catalog['projects']}
    assert len(expected) == 17
    for recipe_id, digest in expected.items():
        encoded = json.dumps(records[recipe_id], ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()
        assert hashlib.sha256(encoded).hexdigest() == digest


def test_empty_detection_does_not_become_demo(client, monkeypatch):
    mock_result(monkeypatch, [])
    assert post(client).json() == {'materials': []}


def test_yogurt_container_is_preserved_and_requested(client, monkeypatch):
    mock_result(monkeypatch, [material(name='Yoğurt kabı', material_id='yogurt_container')])
    response = post(client)
    assert response.status_code == 200
    assert response.json()['materials'][0]['material_id'] == 'yogurt_container'
    assert response.json()['materials'][0]['requires_confirmation'] is True
    assert 'yogurt_container=' in api.PROMPT
    assert 'yogurt_container' in api.Material.model_json_schema()['properties']['material_id']['anyOf'][0]['enum']


def test_real_recipe_catalog_ids_are_supported_by_backend():
    path = Path(__file__).resolve().parents[2] / 'assets' / 'recipes' / 'projects.json'
    catalog = json.loads(path.read_text(encoding='utf-8'))
    assert len(catalog['approved_ids']) == len(set(catalog['approved_ids'])) == 17
    assert len(catalog['projects']) == 17
    assert {project['id'] for project in catalog['projects']} == set(catalog['approved_ids'])
    recipe_ids = {material['material_id'] for project in catalog['projects'] for material in project['required_materials']}
    assert recipe_ids <= api.MATERIAL_IDS
    assert 'yogurt_container' in recipe_ids
    assert 'egg_carton' in recipe_ids


def test_retained_original_recipes_remain_unchanged():
    folder = Path(__file__).resolve().parent
    originals = json.loads((folder / 'original_recipe_hashes.json').read_text(encoding='utf-8'))
    catalog = json.loads((folder.parents[1] / 'assets/recipes/projects.json').read_text(encoding='utf-8'))
    projects = {project['id']: project for project in catalog['projects']}
    assert len(originals) == 7
    for project_id, expected in originals.items():
        serialized = json.dumps(projects[project_id], ensure_ascii=False, sort_keys=True, separators=(',', ':'))
        assert hashlib.sha256(serialized.encode()).hexdigest() == expected


def test_egg_carton_is_preserved_and_requested(client, monkeypatch):
    mock_result(monkeypatch, [material(name='Karton yumurta kolisi', material_id='egg_carton')])
    response = post(client)
    assert response.status_code == 200
    assert response.json()['materials'][0]['material_id'] == 'egg_carton'
    assert 'egg_carton=' in api.PROMPT


@pytest.mark.parametrize('change', [{'quantity': 0}, {'quantity': True}, {'quantity': '2'}, {'quantity': 1000}, {'name': ''}, {'confidence': 'high'}, {'requires_confirmation': 'true'}])
def test_invalid_model_fields(client, monkeypatch, change):
    mock_result(monkeypatch, [material(**change)])
    response = post(client)
    assert response.status_code == 502
    assert response.json()['error']['code'] == 'invalid_analysis'


@pytest.mark.parametrize('raw', ['not json', '```json\n{}\n```', '{}', '{"materials":null}'])
def test_invalid_model_json(raw):
    with pytest.raises(api.AnalysisError) as error:
        api.normalize_analysis(raw)
    assert error.value.code == 'invalid_analysis'


def test_uncertain_always_requires_confirmation():
    item = api.normalize_analysis(json.dumps({'materials': [material(requires_confirmation=False)]})).materials[0]
    assert item.requires_confirmation


def test_missing_key(client, monkeypatch):
    monkeypatch.delenv('GEMINI_API_KEY')
    response = post(client)
    assert response.status_code == 503
    assert response.json()['error']['code'] == 'not_configured'


@pytest.mark.parametrize('data,status,code', [(b'', 400, 'empty_image'), (b'not an image', 415, 'invalid_image'), (b'x' * (api.MAX_UPLOAD_BYTES + 1), 413, 'image_too_large')])
def test_bad_upload(client, data, status, code):
    response = post(client, data)
    assert response.status_code == status
    assert response.json()['error']['code'] == code


def test_missing_file(client):
    assert client.post('/analyze').json()['error']['code'] == 'invalid_request'


def test_mime_is_not_trusted(client, monkeypatch):
    mock_result(monkeypatch, [])
    response = client.post('/analyze', files={'file': ('fake.txt', image_bytes(), 'text/plain')})
    assert response.status_code == 200


def test_gemini_request_contract(monkeypatch):
    real_client = httpx.AsyncClient
    def handler(request):
        assert api.MODEL in str(request.url)
        assert request.headers['x-goog-api-key'] == 'test-only-key'
        assert 'key=' not in str(request.url)
        body = json.loads(request.content)
        assert body['generationConfig']['responseMimeType'] == 'application/json'
        assert body['generationConfig']['responseJsonSchema']['properties']['materials']
        part = body['contents'][0]['parts'][1]['inline_data']
        assert base64.b64decode(part['data']) == b'image'
        return httpx.Response(200, json={'candidates': [{'finishReason': 'STOP', 'content': {'parts': [{'text': '{"materials":[]}'}]}}]})
    monkeypatch.setattr(api.httpx, 'AsyncClient', lambda **kwargs: real_client(transport=httpx.MockTransport(handler), **kwargs))
    assert asyncio.run(api.call_gemini(b'image', 'test-only-key')) == '{"materials":[]}'


@pytest.mark.parametrize('status,expected,code', [
    (400, 502, 'provider_bad_request'),
    (401, 503, 'provider_unauthenticated'),
    (403, 503, 'provider_permission_denied'),
    (404, 503, 'provider_model_not_found'),
    (408, 504, 'analysis_timeout'),
    (429, 429, 'rate_limited'),
    (500, 502, 'provider_internal_error'),
    (503, 503, 'provider_unavailable'),
    (504, 504, 'analysis_timeout'),
    (502, 502, 'provider_error'),
])
def test_upstream_http_errors(monkeypatch, status, expected, code):
    real_client = httpx.AsyncClient
    transport = httpx.MockTransport(lambda request: httpx.Response(status, text='secret provider details'))
    monkeypatch.setattr(api.httpx, 'AsyncClient', lambda **kwargs: real_client(transport=transport, **kwargs))
    with pytest.raises(api.AnalysisError) as error:
        asyncio.run(api.call_gemini(b'image', 'test-only-key'))
    assert (error.value.status, error.value.code) == (expected, code)
    assert 'secret' not in error.value.message


def test_provider_logging_redacts_credentials_and_metadata(caplog):
    credential = 'diagnostic-test-credential'
    response = httpx.Response(400, json={'error': {
        'status': 'INVALID_ARGUMENT',
        'message': f'Invalid schema. {credential}; Authorization: Bearer short-secret; '
                   'x-goog-api-key: hidden-header; user@example.com https://example.com/?key=private',
        'details': [{'metadata': {'consumer': 'private-project', 'key': 'hidden-metadata'}}],
    }})
    api.log_provider_error(response, credential)
    assert 'http_status=400' in caplog.text
    assert 'INVALID_ARGUMENT' in caplog.text
    assert 'Invalid schema' in caplog.text
    for value in [credential, 'short-secret', 'hidden-header', 'user@example.com', 'private-project', 'hidden-metadata', '?key=private']:
        assert value not in caplog.text


def test_configuration_log_contains_only_presence_flags(monkeypatch, caplog):
    import logging
    monkeypatch.setenv('GEMINI_API_KEY', 'test-secret-never-log')
    with caplog.at_level(logging.INFO, logger=api.logger.name):
        api.log_configuration()
    assert 'api_key_present=True' in caplog.text
    assert 'dotenv_loaded=' in caplog.text
    assert 'transport=httpx/REST' in caplog.text
    assert 'test-secret-never-log' not in caplog.text


def test_non_json_provider_error_does_not_log_body(caplog):
    api.log_provider_error(httpx.Response(502, text='<html>private proxy diagnostic</html>'), 'unused')
    assert 'http_status=502' in caplog.text
    assert 'private proxy diagnostic' not in caplog.text


def test_gemini_schema_omits_rejected_maxitems_but_server_limit_remains():
    assert 'maxItems' not in api.gemini_response_schema()['properties']['materials']
    assert api.Detection.model_json_schema()['properties']['materials']['maxItems'] == 50
    with pytest.raises(api.AnalysisError):
        api.normalize_analysis(json.dumps({'materials': [material()] * 51}))


def test_upstream_timeout(monkeypatch):
    real_client = httpx.AsyncClient
    def handler(request):
        raise httpx.ReadTimeout('secret', request=request)
    monkeypatch.setattr(api.httpx, 'AsyncClient', lambda **kwargs: real_client(transport=httpx.MockTransport(handler), **kwargs))
    with pytest.raises(api.AnalysisError) as error:
        asyncio.run(api.call_gemini(b'image', 'test-only-key'))
    assert error.value.status == 504


def test_unexpected_exception_hides_details(monkeypatch):
    async def fail(*args):
        raise RuntimeError('secret key')
    monkeypatch.setenv('GEMINI_API_KEY', 'test-only-key')
    monkeypatch.setattr(api, 'call_gemini', fail)
    with TestClient(api.app, raise_server_exceptions=False) as client:
        response = post(client)
    assert response.status_code == 500
    assert 'secret' not in response.text
